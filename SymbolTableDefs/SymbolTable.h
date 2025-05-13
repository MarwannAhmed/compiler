#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include "ScopeSymbolTable.h"

typedef struct {
    ScopeSymbolTable* head;
    int size;
} SymbolTable;

SymbolTable* SymbolTable_construct();
void SymbolTable_insert(SymbolTable* symbolTable, Symbol* symbol);
Symbol* SymbolTable_get(SymbolTable* symbolTable, char* name);
void SymbolTable_push(SymbolTable* symbolTable);
void SymbolTable_pop(SymbolTable* symbolTable);
void SymbolTable_destroy(SymbolTable* symbolTable);

#endif