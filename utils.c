#include "utils.h"

char* allocateTempVar(int* n) {
    char* label;
    int size = snprintf(NULL, 0, "t%d", *n);
    label = malloc(sizeof(size + 1));
    sprintf(label, "t%d", *n);
    (*n)++;
    return label;
}

void writeSymbolToVisualiser(Symbol* symbol, int depth) {
    char* symbolType;
    char valueData[100] = "";
    switch (symbol->value.type) {
        case TYPE_BOOL:
            symbolType = "bool";
            break;
        case TYPE_INT:
            symbolType = "int";
            break;
        case TYPE_FLOAT:
            symbolType = "float";
            break;
        case TYPE_CHAR:
            symbolType = "char";
            break;
        case TYPE_STRING:
            symbolType = "string";
            break;
        case TYPE_VOID:
            symbolType = "void";
            break;
    }
    if (!symbol->isInit || symbol->value.type == TYPE_VOID) {
        strcpy(valueData, "-");
    } else {
        switch (symbol->value.type) {
            case TYPE_BOOL:
                snprintf(valueData, sizeof(valueData), "%s", symbol->value.data.i ? "true" : "false");
                break;
            case TYPE_INT:
                snprintf(valueData, sizeof(valueData), "%d", symbol->value.data.i);
                break;
            case TYPE_FLOAT:
                snprintf(valueData, sizeof(valueData), "%.5f", symbol->value.data.f);
                break;
            case TYPE_CHAR:
                snprintf(valueData, sizeof(valueData), "%c", symbol->value.data.c);
                break;
            case TYPE_STRING:
                snprintf(valueData, sizeof(valueData), "%s", symbol->value.data.s);
                break;
            default:
                strcpy(valueData, "-");
                break;
        }
    }
    char* symbolKind = symbol->kind == KIND_VAR ? "variable" : (symbol->kind == KIND_CONST ? "constant" : "function");
    fprintf(symbolTableVisualiser, "| %-12s | %-9s | %-12s | %-6s | %-17d |\n", symbol->name, symbolKind, valueData, symbolType, symbol->declLine);
}