#ifndef ZMIENNE_H
#define ZMIENNE_H

typedef enum { INT_TYPE, FLOAT_TYPE, STRING_TYPE } VarType;

typedef struct {
    char* name;
    VarType type;
    void* address;
} Symbol;

void add_symbol(char* name, VarType type, int size);
void* get_symbol_address(char* name);
char* get_symbol_value(void* address, VarType type);
VarType get_symbol_type(char* name);
int is_number(const char* str);

#endif
