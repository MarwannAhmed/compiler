#include "Quad.h"

Quad* Quad_construct(char* operation, char* operand1, char* operand2, char* result) {
    Quad* quad = malloc(sizeof(Quad));
    quad->operation = operation;
    quad->operand1 = operand1;
    quad->operand2 = operand2;
    quad->result = result;
}

void Quad_destroy(Quad* quad) {
    free(quad);
}