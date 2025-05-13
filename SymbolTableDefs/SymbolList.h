#ifndef SYMBOLLIST_H
#define SYMBOLLIST_H

#include "Symbol.h"

typedef struct {
    Symbol* head;
    int size;
} SymbolList;

SymbolList* SymbolList_construct();
void SymbolList_insert(SymbolList* symbolList, Symbol* symbol);
Symbol* SymbolList_get(SymbolList* symbolList, char* name);
void SymbolList_destroy(SymbolList* symbolList);

#endif