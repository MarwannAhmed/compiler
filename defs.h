#ifndef DEFS_H
#define DEFS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

typedef enum {
    KIND_VAR,
    KIND_CONST,
    KIND_FUNC
} Kind;

typedef enum {
    TYPE_BOOL,
    TYPE_INT,
    TYPE_FLOAT,
    TYPE_CHAR,
    TYPE_STRING,
    TYPE_VOID
} Type;

typedef struct {
    Type type;
    union
    {
        int i;
        float f;
        char c;
        char *s;
    } data;
} Value;

#endif