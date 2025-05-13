#include "utils.h"
#include "defs.h"

char* addTempVar(int* n) {
    char* label;
    int size = snprintf(NULL, 0, "t%d", *n);
    label = malloc(sizeof(size + 1));
    sprintf(label, "t%d", *n);
    (*n)++;
    return label;
}