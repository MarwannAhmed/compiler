#ifndef GLOBALS_H
#define GLOBALS_H

#include "SymbolTableDefs/SymbolTable.h"

extern FILE* symbolTableFile;
extern FILE* semanticAnalysisFile;
extern FILE* symbolTableVisualiser;
extern int line;
extern SymbolTable* symbolTable;
extern int numParams;
extern Symbol* lastSymbol;
extern int numArgs;
extern int numCases;
extern Symbol* currFunc;
extern int funcDepth;

#endif