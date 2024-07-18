#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "zmienne.h"

#define SYMBOL_TABLE_SIZE 1000

Symbol symbol_table[SYMBOL_TABLE_SIZE]; 
unsigned int symbol_table_index = 0;

void add_symbol(char* name, VarType type, int size) {
    symbol_table[symbol_table_index].name = strdup(name);
    symbol_table[symbol_table_index].type = type;
    void* allocated_memory;
    switch (type) {
        case INT_TYPE:
            allocated_memory = malloc(sizeof(int) * size);
            break;
        case FLOAT_TYPE:
            allocated_memory = malloc(sizeof(float) * size);
            break;
        case STRING_TYPE:
            allocated_memory = malloc(sizeof(char*) * size);
            break;
        default:
            exit(1);
    }

    symbol_table[symbol_table_index].address = allocated_memory;
    symbol_table_index++;
}

void* get_symbol_address(char* name) {
    for (int i = 0; i < symbol_table_index; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].address;
        }
    }
    fprintf(stderr, "Nie ma adresu takiej zmiennej: %s\n", name);
    return NULL;
}

char* get_symbol_value(void* address, VarType type) {
    char* value_str = (char*)malloc(20);

    switch (type) {
        case INT_TYPE: {
            int* value_ptr = (int*)address;
            snprintf(value_str, 20, "%d", *value_ptr);
            break;
        }
        case FLOAT_TYPE: {
            float* value_ptr = (float*)address;
            snprintf(value_str, 20, "%f", *value_ptr);
            break;
        }
        case STRING_TYPE: {
            char** value_ptr = (char**)address;
            snprintf(value_str, 20, "%s", *value_ptr);
            break;
        }
        default:
            free(value_str);
            return NULL;
    }
    return value_str;
}

VarType get_symbol_type(char* name) {
    for (int i = 0; i < symbol_table_index; i++) {
        if (strcmp(symbol_table[i].name, name) == 0) {
            return symbol_table[i].type;
        }
    }
    fprintf(stderr, "Nie ma typu takiej zmiennej: %s\n", name);
    exit(1);
}

int is_number(const char* str) {
    while (*str) {
        if (!isdigit(*str) && *str != '.') return 0;
        str++;
    }
    return 1;
}