#include "SymbolTable.h"

SymbolTable* SymbolTable_construct() {
    SymbolTable* symbolTable = malloc(sizeof(SymbolTable));
    symbolTable->head = ScopeSymbolTable_construct();
    symbolTable->size = 1;
    return symbolTable;
}

void SymbolTable_insert(SymbolTable* symbolTable, Symbol* symbol) {
    ScopeSymbolTable* scopeSymbolTable = symbolTable->head;
    ScopeSymbolTable_insert(scopeSymbolTable, symbol);
}

Symbol* SymbolTable_get(SymbolTable* symbolTable, char* name) {
    ScopeSymbolTable* currentScopeSymbolTable = symbolTable->head;
    while(currentScopeSymbolTable) {
        Symbol* symbol = ScopeSymbolTable_get(currentScopeSymbolTable, name);
        if (symbol) {
            return symbol;
        }
        currentScopeSymbolTable = currentScopeSymbolTable->next;
    }
    return NULL;
}

void SymbolTable_push(SymbolTable* symbolTable) {
    ScopeSymbolTable* scopeSymbolTable = ScopeSymbolTable_construct();
    scopeSymbolTable->next = symbolTable->head;
    symbolTable->head = scopeSymbolTable;
    symbolTable->size = symbolTable->size + 1;
}

void SymbolTable_pop(SymbolTable* symbolTable) {
    ScopeSymbolTable* scopeSymbolTable = symbolTable->head;
    symbolTable->head = scopeSymbolTable->next;
    scopeSymbolTable->next = NULL;
    ScopeSymbolTable_destroy(scopeSymbolTable);
    symbolTable->size = symbolTable->size - 1;
}

void SymbolTable_destroy(SymbolTable* symbolTable) {
    ScopeSymbolTable_destroy(symbolTable->head);
    free(symbolTable);
}