#include "ScopeSymbolTable.h"

ScopeSymbolTable* ScopeSymbolTable_construct() {
    ScopeSymbolTable* scopeSymbolTable = malloc(sizeof(ScopeSymbolTable));
    for (int i = 0; i < 100; i++) {
        scopeSymbolTable->table[i] = SymbolList_construct();
    }
    scopeSymbolTable->next = NULL;
    return scopeSymbolTable;
}

unsigned int ScopeSymbolTable_hash(char* name) {
    unsigned int hash = 5381;
    for (int i = 0; i < strlen(name); i++) {
        hash = ((hash << 5) + hash) + name[i];
    }
    return hash % 100;
}

void ScopeSymbolTable_insert(ScopeSymbolTable* scopeSymbolTable, Symbol* symbol) {
    int index = ScopeSymbolTable_hash(symbol->name);
    SymbolList_insert(scopeSymbolTable->table[index], symbol);
}

Symbol* ScopeSymbolTable_get(ScopeSymbolTable* scopeSymbolTable, char* name) {
    int index = ScopeSymbolTable_hash(name);
    return SymbolList_get(scopeSymbolTable->table[index], name);
}

void ScopeSymbolTable_destroy(ScopeSymbolTable* scopeSymbolTable) {
    for (int i = 0; i < 100; i++) {
        SymbolList_destroy(scopeSymbolTable->table[i]);
    }
    if (scopeSymbolTable->next) {
        ScopeSymbolTable_destroy(scopeSymbolTable->next);
    }
    free(scopeSymbolTable);
}