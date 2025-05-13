#ifndef SYMBOL_H
#define SYMBOL_H

#include "../defs.h"

typedef struct Symbol {
    char* name;
    Kind kind;
    int isInit;
    int declLine;
    int isUsed;
    Value value;
    struct Symbol** params;
    int numParams;
    struct Symbol* next;
} Symbol;

Symbol* Symbol_construct(char* name, Kind kind, int isInit, int declLine, Value value, Symbol** params, int numParams);
void Symbol_destroy(Symbol* symbol, int verbose);

#endif