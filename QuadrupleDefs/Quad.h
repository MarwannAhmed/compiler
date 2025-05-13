#ifndef QUAD_H
#define QUAD_H

typedef struct {
    char* operation;
    char* operand1;
    char* operand2;
    char* result;
} Quad;

Quad* Quad_construct(char* operation, char* operand1, char* operand2, char* result);
void Quad_destroy(Quad* quad);

#endif QUAD_H