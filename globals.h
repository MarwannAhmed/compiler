#ifndef GLOBALS_H
#define GLOBALS_H

#include "SymbolTableDefs/SymbolTable.h"

extern FILE* symbolTableFile;
extern FILE* semanticAnalysisFile;
extern FILE* symbolTableVisualiser;
extern FILE* quadruplesFile;
extern int line;
extern SymbolTable* symbolTable;
extern int numParams;
extern Symbol* lastSymbol;
extern int numArgs;
extern int numCases[100];
extern Symbol* currFunc;
extern int funcDepth;
extern int tempVars;
extern int labels;
extern Value* switchExpr[100];
extern int switchDepth;
extern char* labelNames[1000];
extern int labelDepth;
extern int switchLabel[100];
extern char* forIterator[100];
extern int forDepth;
#endif