#include "globals.h"

FILE* symbolTableFile = NULL;
FILE* semanticAnalysisFile = NULL;
FILE* quadruplesFile = NULL;
int line = 1;
SymbolTable* symbolTable = NULL;
int numParams = 0;
Symbol* lastSymbol = NULL;
int numArgs = 0;
int numCases[100];
Symbol* currFunc = NULL;
int funcDepth = 0;
int tempVars = 0;
int labels = 0;
Value* switchExpr[100];
int switchDepth = 0;
char* labelNames[1000];
int labelDepth = 0;
int switchLabel[100];