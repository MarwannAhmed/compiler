#ifndef SCOPESYMBOLTABLE_H
#define SCOPESYMBOLTABLE_H

#include "SymbolList.h"

typedef struct ScopeSymbolTable {
    SymbolList* table[100];
    struct ScopeSymbolTable* next;
} ScopeSymbolTable;

ScopeSymbolTable* ScopeSymbolTable_construct();
unsigned int ScopeSymbolTable_hash(char* name);
void ScopeSymbolTable_insert(ScopeSymbolTable* scopeSymbolTable, Symbol* symbol);
Symbol* ScopeSymbolTable_get(ScopeSymbolTable* scopeSymbolTable, char* name);
void ScopeSymbolTable_destroy(ScopeSymbolTable* scopeSymbolTable);

#endif