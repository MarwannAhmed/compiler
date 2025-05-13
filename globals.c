#include "globals.h"

FILE* symbolTableFile = NULL;
FILE* semanticAnalysisFile = NULL;
FILE* quadruplesFile = NULL;
int line = 1;
SymbolTable* symbolTable = NULL;
int numParams = 0;
Symbol* lastSymbol = NULL;
int numArgs = 0;
int numCases = 0;
Symbol* currFunc = NULL;
int funcDepth = 0;
int tempVars = 0;