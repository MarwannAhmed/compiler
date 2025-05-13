#include "SymbolList.h"

SymbolList* SymbolList_construct() {
    SymbolList* symbolList = malloc(sizeof(SymbolList));
    symbolList->head = NULL;
    symbolList->size = 0;
    return symbolList;
}

void SymbolList_insert(SymbolList* symbolList, Symbol* symbol) {
    symbol->next = symbolList->head;
    symbolList->head = symbol;
    symbolList->size = symbolList->size + 1;
}

Symbol* SymbolList_get(SymbolList* symbolList, char* name) {
    Symbol* currentSymbol = symbolList->head;
    while (currentSymbol) {
        if (strcmp(currentSymbol->name, name) == 0) {
            return currentSymbol;
        }
        currentSymbol = currentSymbol->next;
    }
    return NULL;
}

void SymbolList_destroy(SymbolList* symbolList) {
    if (symbolList->head) {
        Symbol_destroy(symbolList->head, 1);
    }
    free(symbolList);
}