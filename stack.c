#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "stack.h"


void push(Stos *s, char *str) {
    if (s->top < STACK_SIZE - 1) {
        s->data[++(s->top)] = strdup(str);
        printf("%s ", str); // Debug print
    } else {
        fprintf(stderr, "Stack overflow\n");
    }
}

char* pop(Stos *s) {
    if (s->top >= 0) {
        char *str = s->data[(s->top)--];
        printf("(%s)", str); // Debug print
        return str;
    } else {
        fprintf(stderr, "Stack underflow\n");
        return NULL;
    }
}

void operacja(Stos *s) {
    char *op = pop(s);
    char *arg1 = pop(s);
    char *arg2 = pop(s);
    if (arg1 && arg2 && op) {
        int result;
        char res_str[20];
        if (strcmp(op, "+") == 0) {
            result = atoi(arg2) + atoi(arg1);
        } else if (strcmp(op, "-") == 0) {
            result = atoi(arg2) - atoi(arg1);
        } else if (strcmp(op, "*") == 0) {
            result = atoi(arg2) * atoi(arg1);
        } else if (strcmp(op, "/") == 0) {
            if (atoi(arg1) == 0) {
                fprintf(stderr, "Dzielenie przez zero\n");
                free(arg1);
                free(arg2);
                free(op);
                return;
            }
            result = atoi(arg2) / atoi(arg1);
        } else {
            fprintf(stderr, "Nieznany operator: %s\n", op);
            free(arg1);
            free(arg2);
            free(op);
            return;
        }
        snprintf(res_str, 20, "%d", result);
        push(s, res_str);
    }
    free(arg1);
    free(arg2);
    free(op);
}
