#include "globals.h"

int line = 1;
SymbolTable* symbolTable = NULL;
int numParams = 0;
Symbol* lastSymbol = NULL;
int numArgs = 0;
int numCases = 0;
Symbol* currFunc = NULL;
int funcDepth = 0;