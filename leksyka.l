%{
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "gramatyka.tab.h"
FILE *wyjscie;
int linia;
FILE *zm;
%}

%%
\"[^\"]*\" { yylval.str = strdup(yytext); return STRING_TEXT; }
"=" { return ASSIGN; }
"==" { return EQ; }
"!=" { return NEQ; }
"+" { return PLUS; }
"-" { return MINUS; }
"/" { return DIVIDE; }
"*" { return MULTIPLY; }
"++" { return INC; }
"--" { return DEC; }
">" { return GT; }
"<" { return LT; }
">=" { return GTE; }
"<=" { return LTE; }
"(" { return LDUHA; }
")" { return RDUHA; }
"[" { return LKDUHA; }
"]" { return RKDUHA; }
[\t]+ { return TAB; }
"    " { return TAB; }
"\n" { return NL; }
":" {return COLON; }
"int" { return INT; }
"float" { return FLOAT; }
"string" { return STR; }
"array" { return ARR; }
"and" { return AND; }
"or" { return OR; }
"not" { return NOT; }
"if" { return IF; }
"else" { return ELSE; }
"while" { return WHILE; }
[a-z][a-z0-9]* { yylval.str = strdup(yytext); return VAR; }
[0-9]+ { yylval.str = strdup(yytext); return NUM; }
[0-9]+"."[0-9]+ { yylval.str = strdup(yytext); return FLNUM; }
%%

int main(int argc, char **argv) {
    linia = 1;
    wyjscie = fopen("output.asm", "w");
    printf("Uruchamiam kompilacje pliku zrodlowego\n");
    if (argc > 0) {
        yyin = fopen(argv[1], "r");
        zm = fopen("zmienne.txt", "w");
        printf("Poprawne otwarcie pliku\n");
        yyparse();
        //dokonajAsemblacji();
        printf("\nKompilacja zakonczona\n");
        fclose(yyin);
        fclose(zm);
        fclose(wyjscie);
    } else {
        printf("Brak pliku wejsciowego\n");
    }
    return 0;
}
