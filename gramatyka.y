%{
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "stack.h"
#include "zmienne.h"

extern FILE *wyjscie;
extern FILE *zm;
extern char *yytext;
extern int linia;
int condition_count = 0;

Stos op_stack;

void yyerror(char *msg);
int yylex(void);
%}

%union {
    char *str;
    int num;
}

%token <str> ASSIGN EQ NEQ PLUS MINUS DIVIDE MULTIPLY INC DEC GT LT GTE LTE AND OR NOT IF ELSE WHILE
%token <str> LDUHA RDUHA LKDUHA RKDUHA TAB NL COLON INT FLOAT STR ARR VAR NUM FLNUM STRING_TEXT
%left MULTIPLY DIVIDE PLUS MINUS
%left AND OR GT LT GTE LTE EQ NEQ

%%
input:
    line { linia++; }
    | input line { linia++; }
    ;

line:
    decl
    | defi
    | ifBody
    | whileBody
    | NL
    ;

decl: 
    INT VAR NL { 
        add_symbol((yyvsp[-1].str), INT_TYPE, 1); 
    }
    | INT VAR ASSIGN expr NL { 
        add_symbol((yyvsp[-3].str), INT_TYPE, 1); 
        char* value = pop(&op_stack); 
        int* address = (int*)get_symbol_address((yyvsp[-3].str));
        *address = atoi(value);
        fprintf(zm, "%s: %p %d\n", (yyvsp[-3].str), (void*)address, *address);
        fprintf(wyjscie, "mov dword ptr [%p], %d\n", (void*)address, *address);
        free(value);
    }
    | FLOAT VAR NL { 
        add_symbol((yyvsp[-1].str), FLOAT_TYPE, 1); 
    }
    | FLOAT VAR ASSIGN expr NL { 
        add_symbol((yyvsp[-3].str), FLOAT_TYPE, 1);  
        char* value = pop(&op_stack); 
        float* address = (float*)get_symbol_address((yyvsp[-3].str));
        *address = atof(value);
        fprintf(zm, "%s: %p %f\n", (yyvsp[-3].str), (void*)address, *address); 
        fprintf(wyjscie, "movss [%p], %f\n", (void*)address, *address); 
        free(value);
    }
    | STR VAR NL { 
        add_symbol((yyvsp[-1].str), STRING_TYPE, 1);
    }
    | STR VAR ASSIGN STRING_TEXT NL { 
        add_symbol((yyvsp[-3].str), STRING_TYPE, 1); 
        char** address = (char**)get_symbol_address((yyvsp[-3].str));
        *address = strdup((yyvsp[-1].str));
        fprintf(zm, "%s: %p %s\n", (yyvsp[-3].str), (void*)address, *address); 
        fprintf(wyjscie, "mov dword ptr [%p], %s\n", (void*)address, *address); 
    }
    | INT VAR ASSIGN arrDecl NL { 
        int arraySize = (yyvsp[-1].num);
        add_symbol((yyvsp[-3].str), INT_TYPE, arraySize); 
        fprintf(zm, "%s tablica z %d elementow\n", (yyvsp[-3].str), arraySize); 
        free((yyvsp[-3].str));
    }
    ;

arrDecl:
    ARR LDUHA NUM RDUHA { 
        (yyval.num) = atoi((yyvsp[-1].str));
    }
    | ARR LDUHA arrDecl RDUHA { 
        (yyval.num) = (yyvsp[-1].num);
    }
    ;

defi:
    VAR ASSIGN expr NL { 
        char* value = pop(&op_stack); 
        VarType type = get_symbol_type((yyvsp[-3].str));
        void* address = get_symbol_address((yyvsp[-3].str));
        switch (type) {
            case INT_TYPE:
                *(int*)address = atoi(value);
                fprintf(wyjscie, "mov dword ptr [%p], %d\n", (void*)address, *(int*)address);
                break;
            case FLOAT_TYPE:
                *(float*)address = atof(value);
                fprintf(wyjscie, "movss [%p], %f\n", (void*)address, *(float*)address);
                break;
            case STRING_TYPE:
                break;
        }
        fprintf(zm, "%s: %p %s\n", (yyvsp[-3].str), (void*)address, value);
        free(value);
    }
    | VAR ASSIGN STRING_TEXT NL { 
        char** address = (char**)get_symbol_address((yyvsp[-3].str));
        *address = strdup((yyvsp[-1].str));
        fprintf(zm, "%s: %p %s\n", (yyvsp[-3].str), (void*)address, *address);
        fprintf(wyjscie, "mov dword ptr [%p], %s\n", (void*)address, *address);
    }
    | VAR LKDUHA NUM RKDUHA ASSIGN expr NL { 
        char* value = pop(&op_stack); 
        void* base_address = get_symbol_address((yyvsp[-6].str));
        int* element_address = (int*)base_address + atoi((yyvsp[-4].str));
        *element_address = atoi(value);
        fprintf(zm, "%s[%d] %p %s\n", (yyvsp[-6].str), atoi((yyvsp[-4].str)), (void*)element_address, value); 
        fprintf(wyjscie, "mov dword ptr [%p], %d\n", (void*)element_address, *element_address);
        free(value);
    }
    | VAR INC NL { 
        int* address = (int*)get_symbol_address((yyvsp[-2].str));
        (*address)++;
        fprintf(zm, "%s: %p %d\n", (yyvsp[-2].str), (void*)address, *address);
        fprintf(wyjscie, "incl dword ptr [%p]\n", (void*)address);
    }
    | VAR DEC NL { 
        int* address = (int*)get_symbol_address((yyvsp[-2].str));
        (*address)--;
        fprintf(zm, "%s: %p %d\n", (yyvsp[-2].str), (void*)address, *address);
        fprintf(wyjscie, "decl dword ptr [%p]\n", (void*)address);
    }
    ;

expr:
    NUM { 
        push(&op_stack, yytext);
    }
    | FLNUM { 
        push(&op_stack, yytext); 
    }
    | VAR { 
        void* address = get_symbol_address((yyvsp[-0].str));
        VarType type = get_symbol_type((yyvsp[-0].str));
        char* value = get_symbol_value(address, type);
        push(&op_stack, value);
        free(value);
    }
    | VAR LKDUHA expr RKDUHA { 
        void* base_address = get_symbol_address((yyvsp[-3].str));
        int index = atoi(pop(&op_stack));
        int* element_address = (int*)(base_address + index * sizeof(int));
        char* value = get_symbol_value((void*)element_address, INT_TYPE);
        push(&op_stack, value);
        free(value);
    }
    | LDUHA expr RDUHA
    | expr PLUS expr { push(&op_stack, "+"); operacja(&op_stack);}
    | expr MINUS expr { push(&op_stack, "-"); operacja(&op_stack);}
    | expr MULTIPLY expr { push(&op_stack, "*"); operacja(&op_stack);}
    | expr DIVIDE expr { push(&op_stack, "/"); operacja(&op_stack);}
    | MINUS expr { push(&op_stack, "-1"); push(&op_stack, "*"); operacja(&op_stack); }
    ;

warunek:
    NUM { 
        fprintf(wyjscie, "push %s\n", yytext);
    }
    | FLNUM { 
        fprintf(wyjscie, "push %s\n", yytext); 
    }
    | VAR { 
        void* address = get_symbol_address((yyvsp[-0].str));
        fprintf(wyjscie, "push [%p]\n", (void*)address);
    }
    | VAR LKDUHA expr RKDUHA { 
        void* base_address = get_symbol_address((yyvsp[-3].str));
        int index = atoi(pop(&op_stack));
        int* element_address = (int*)(base_address + index * sizeof(int));
        fprintf(wyjscie, "push [%p]\n", (int*)element_address);
    }
    | LDUHA warunek RDUHA {
        (yyval.str) = (yyvsp[-1].str);
    }
    | warunek AND warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "and eax, ebx\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek OR warunek{
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "or eax, ebx\n");
        fprintf(wyjscie, "push eax\n");
    }
    | NOT warunek{
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "not eax\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek EQ warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "cmp eax, ebx\n");
        fprintf(wyjscie, "sete al\n"); //sets its argument to 1 if the zero flag is set or to 0 otherwise
        fprintf(wyjscie, "movzx eax, al\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek NEQ warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "cmp eax, ebx\n");
        fprintf(wyjscie, "setne al\n");
        fprintf(wyjscie, "movzx eax, al\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek GT warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "cmp eax, ebx\n");
        fprintf(wyjscie, "setg al\n");
        fprintf(wyjscie, "movzx eax, al\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek LT warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "cmp eax, ebx\n");
        fprintf(wyjscie, "setl al\n");
        fprintf(wyjscie, "movzx eax, al\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek GTE warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "cmp eax, ebx\n");
        fprintf(wyjscie, "setge al\n");
        fprintf(wyjscie, "movzx eax, al\n");
        fprintf(wyjscie, "push eax\n");
    }
    | warunek LTE warunek {
        fprintf(wyjscie, "pop ebx\n");
        fprintf(wyjscie, "pop eax\n");
        fprintf(wyjscie, "cmp eax, ebx\n");
        fprintf(wyjscie, "setle al\n");
        fprintf(wyjscie, "movzx eax, al\n");
        fprintf(wyjscie, "push eax\n");
    }
    ;


ifBody:
    IF LDUHA warunek RDUHA COLON NL{
        {fprintf(wyjscie, "pop eax\n");}
        {fprintf(wyjscie, "cmp eax, 0:\n");}
        {fprintf(wyjscie, "je condition_end_%d:\n", condition_count);}
    }insideblock{
        fprintf(wyjscie, "condition_end_%d:\n", condition_count);
        condition_count++;
    }
    ;


whileBody:
    {fprintf(wyjscie, "condition_begin_%d:\n", condition_count);}
    WHILE LDUHA warunek RDUHA COLON NL{
        {fprintf(wyjscie, "pop eax\n");}
        {fprintf(wyjscie, "cmp eax, 0:\n");}
        {fprintf(wyjscie, "je condition_end_%d:\n", condition_count);}
    }insideblock{
        fprintf(wyjscie, "jmp condition_begin_%d:\n", condition_count);
        fprintf(wyjscie, "condition_end_%d:\n", condition_count);
        condition_count++;
    }
    ;

insideblock:
    bodyline { linia++; }
    | insideblock bodyline { linia++; }
    ;

bodyline:
    TAB line 
    | bodyline TAB line
    ;

%%

void yyerror(char *msg) {
    printf("Blad w linijce %i: %s\n", linia, msg);
    exit(-1);
}