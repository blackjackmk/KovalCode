#ifndef STACK_H
#define STACK_H

#define STACK_SIZE 100

typedef struct {
    char *data[STACK_SIZE];
    int top;
} Stos;

void push(Stos *s, char *str);
char* pop(Stos *s);
void operacja(Stos *s);

#endif // STACK_H
