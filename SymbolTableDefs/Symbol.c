#include "Symbol.h"

Symbol* Symbol_construct(char* name, Kind kind, int isInit, Value value, Symbol** params, int numParams) {
    Symbol* symbol = malloc(sizeof(Symbol));
    symbol->name = name;
    symbol->kind = kind;
    symbol->isInit = isInit;
    symbol->value = value;
    if (numParams > 0) {
        symbol->params = malloc(numParams * sizeof(Symbol*));
        memcpy(symbol->params, params, numParams * sizeof(Symbol*));
    }
    symbol->numParams = numParams;
    symbol->next = NULL;
    return symbol;
}

void Symbol_destroy(Symbol* symbol) {
    for (int i = 0; i < symbol->numParams; i++) {
        Symbol_destroy(symbol->params[i]);
    }
    if (symbol->numParams > 0) {
        free(symbol->params);
    }
    if (symbol->next) {
        Symbol_destroy(symbol->next);
    }
    free(symbol);
}