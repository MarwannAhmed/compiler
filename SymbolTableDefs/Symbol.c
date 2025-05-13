#include "Symbol.h"

Symbol* Symbol_construct(char* name, Kind kind, int isInit, int declLine, Value value, Symbol** params, int numParams) {
    Symbol* symbol = malloc(sizeof(Symbol));
    symbol->name = name;
    symbol->kind = kind;
    symbol->isInit = isInit;
    symbol->declLine = declLine;
    symbol->isUsed = 0;
    symbol->value = value;
    if (numParams > 0) {
        symbol->params = malloc(numParams * sizeof(Symbol*));
        memcpy(symbol->params, params, numParams * sizeof(Symbol*));
    }
    symbol->numParams = numParams;
    symbol->next = NULL;
    return symbol;
}

void Symbol_destroy(Symbol* symbol, int verbose) {
    if (verbose && !symbol->isUsed) {
        printf("Warning: Unused symbol \"%s\" at line %d\n", symbol->name, symbol->declLine);
    }
    for (int i = 0; i < symbol->numParams; i++) {
        Symbol_destroy(symbol->params[i], 0);
    }
    if (symbol->numParams > 0) {
        free(symbol->params);
    }
    if (symbol->next) {
        Symbol_destroy(symbol->next, 1);
    }
    free(symbol);
}