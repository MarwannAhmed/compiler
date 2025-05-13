/* Definitions */
%{
    #include "globals.h"
    #include "utils.h"

    void yyerror(const char* s);
    int yylex(void);
    extern FILE* yyin;

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

%}

%union {
    int i;
    float f;
    char c;
    char* s;
    Value* v;
    Value** vl;
    Symbol* p;
    Symbol** pl;
}
%token <i> BOOL
%token <i> INTEGER
%token <f> FLOAT
%token <c> CHAR
%token <s> STRING
%token <s> TYPE
%token <s> IDENTIFIER
%token VOID
%token IF
%token ELSE
%token SWITCH
%token CASE
%token DEFAULT
%token FOR
%token FROM
%token TO
%token STEP
%token WHILE
%token REPEAT
%token UNTIL
%token CONST
%token RETURN
%token PRINT
%token SEMICOLON
%token COMMA
%token ASSIGN
%token PLUS
%token MINUS
%token MULT
%token DIV
%token MOD
%token POW
%token OPENING_PARENTHESIS
%token CLOSING_PARENTHESIS
%token SCOPE_START
%token SCOPE_END
%token OR
%token AND
%token NOT
%token LE
%token GE
%token LT
%token GT
%token EQ
%token NE
%type<p> parameter
%type<pl> parameter_list
%type <v> expression mathematical_expression mathematical_term mathematical_exponent logical_expression logical_conjunction logical_comparison primary argument function_call case_statement decision iterator switch_header case_header
%type<vl> argument_list case_statements
/* Production Rules */
%%
program : statements
        ;

statements : statements statement
           | statement
           ;

statement : block
          | declaration SEMICOLON
          | assignment SEMICOLON
          | if_statement
          | switch_statement
          | for_loop
          | while_loop
          | repeat_loop
          | function_declaration
          | return_statement SEMICOLON
          | function_call SEMICOLON
          | print_statement SEMICOLON
          ;

block : SCOPE_START {
                        if (currFunc) {
                            funcDepth = funcDepth + 1;
                        }
                        for (int i = 0; i < symbolTable->size; i++) {
                            fprintf(symbolTableFile, "    ");
                            fprintf(symbolTableVisualiser, "    ");
                        }
                        fprintf(symbolTableFile, "Constructing new table for a new scope: %d\n", symbolTable->size);
                        fprintf(symbolTableVisualiser, "Symbol table for new scope: %d\n", symbolTable->size);
                        for (int i = 0; i < symbolTable->size; i++) {
                            fprintf(symbolTableVisualiser, "    ");
                        }
                        fprintf(symbolTableVisualiser, "| %-12s | %-9s | %-12s | %-6s | %-17s |\n", "name", "kind", "value", "type", "declaration line");
                        for (int i = 0; i < symbolTable->size; i++) {
                            fprintf(symbolTableVisualiser, "    ");
                        }
                        fprintf(symbolTableVisualiser, "------------------------------------------------------------------------\n");
                        SymbolTable_push(symbolTable);
                        if (lastSymbol && lastSymbol->kind == KIND_FUNC && currFunc) {
                            fprintf(semanticAnalysisFile, "Line %d: Invalid statement: cannot declare a function inside a function.", line);
                            yyerror("Invalid statement: cannot declare a function inside a function.");
                        }
                        if (lastSymbol && lastSymbol->kind == KIND_FUNC && !currFunc) {
                            currFunc = lastSymbol;
                        }
                        if (lastSymbol && lastSymbol->kind == KIND_FUNC && lastSymbol->numParams > 0) {
                            for (int i = 0; i < numParams; i++) {
                                Symbol* param = lastSymbol->params[i];
                                if (ScopeSymbolTable_get(symbolTable->head, param->name)) {
                                    fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                    yyerror("Invalid declaration: cannot redeclare symbol.");
                                }
                                char* type_str;
                                switch (param->value.type) {
                                    case TYPE_BOOL:
                                        type_str = "bool";
                                        break;
                                    case TYPE_INT:
                                        type_str = "int";
                                        break;
                                    case TYPE_FLOAT:
                                        type_str = "float";
                                        break;
                                    case TYPE_CHAR:
                                        type_str = "char";
                                        break;
                                    case TYPE_STRING:
                                        type_str = "string";
                                        break;
                                }
                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                    fprintf(symbolTableFile, "    ");
                                    fprintf(symbolTableVisualiser, "    ");
                                }
                                fprintf(symbolTableFile, "Declared a function parameter \"%s\" of type \"%s\"\n", param->name, type_str);
                                Symbol* symbol = Symbol_construct(param->name, param->kind, param->isInit, line, param->value, NULL, 0);
                                SymbolTable_insert(symbolTable, symbol);
                                writeSymbolToVisualiser(symbol, symbolTable->size);
                            }
                        }
                    }
        statements
        SCOPE_END   {
                        if (funcDepth == 0) {
                            currFunc = NULL;
                        }
                        for (int i = 0; i < symbolTable->size - 1; i++) {
                            fprintf(symbolTableFile, "    ");
                        }
                        fprintf(symbolTableFile, "Destroying table for scope: %d\n", symbolTable->size - 1);
                        SymbolTable_pop(symbolTable);
                        for (int i = 0; i < symbolTable->size - 1; i++) {
                            fprintf(symbolTableVisualiser, "    ");
                        }
                        if(symbolTable->size == 1) {
                            fprintf(symbolTableVisualiser, "Returning to symbol table for global scope.\n");
                        }
                        else {
                            fprintf(symbolTableVisualiser, "Returning to symbol table for scope: %d.\n", symbolTable->size - 1);
                        }
                        if (currFunc) {
                            funcDepth = funcDepth - 1;
                        }
                    }
      ;

declaration : TYPE IDENTIFIER                           {
                                                            if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                yyerror("Invalid declaration: cannot redeclare symbol.");
                                                            }
                                                            Value value;
                                                            if (strcmp($1, "bool") == 0) {
                                                                value.type = TYPE_BOOL;
                                                            }
                                                            else if (strcmp($1, "int") == 0) {
                                                                value.type = TYPE_INT;
                                                            }
                                                            else if (strcmp($1, "float") == 0) {
                                                                value.type = TYPE_FLOAT;
                                                            }
                                                            else if (strcmp($1, "char") == 0) {
                                                                value.type = TYPE_CHAR;
                                                            }
                                                            else if (strcmp($1, "string") == 0) {
                                                                value.type = TYPE_STRING;
                                                            }
                                                            else {
                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot create a variable of unknown type.", line);
                                                                yyerror("Invalid declaration: cannot create a variable of unknown type.");
                                                            }
                                                            for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                fprintf(symbolTableFile, "    ");
                                                                fprintf(symbolTableVisualiser, "    ");
                                                            }
                                                            fprintf(symbolTableFile, "Declared a variable \"%s\" of type \"%s\"\n", $2, $1);
                                                            Symbol* symbol = Symbol_construct($2, KIND_VAR, 0, line, value, NULL, 0);
                                                            SymbolTable_insert(symbolTable, symbol);
                                                            writeSymbolToVisualiser(symbol, symbolTable->size);
                                                            lastSymbol = symbol;
                                                        }
            | TYPE IDENTIFIER ASSIGN expression         {
                                                            if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                yyerror("Invalid declaration: cannot redeclare symbol.");
                                                            }
                                                            Value value;
                                                            if (strcmp($1, "bool") == 0) {
                                                                value.type = TYPE_BOOL;
                                                                if ($4->type != TYPE_BOOL) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-boolean expression to \"bool\" variable.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-boolean expression to \"bool\" variable.");
                                                                }
                                                                value.data.i = $4->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a variable \"%s\" of type \"%s\" and value: %s\n", $2, $1, value.data.i == 1 ? "true" : "false");
                                                            }
                                                            else if (strcmp($1, "int") == 0) {
                                                                value.type = TYPE_INT;
                                                                if ($4->type != TYPE_INT && $4->type != TYPE_FLOAT) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-numeric expression to \"int\" variable.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"int\" variable.");
                                                                }
                                                                value.data.i = $4->type == TYPE_INT ? $4->data.i : (int) $4->data.f;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a variable \"%s\" of type \"%s\" and value: %d\n", $2, $1, value.data.i);
                                                            }
                                                            else if (strcmp($1, "float") == 0) {
                                                                value.type = TYPE_FLOAT;
                                                                if ($4->type != TYPE_INT && $4->type != TYPE_FLOAT) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-numeric expression to \"float\" variable.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"float\" variable.");
                                                                }
                                                                value.data.f = $4->type == TYPE_FLOAT ? $4->data.f : (float) $4->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a variable \"%s\" of type \"%s\" and value: %f\n", $2, $1, value.data.f);
                                                            }
                                                            else if (strcmp($1, "char") == 0) {
                                                                value.type = TYPE_CHAR;
                                                                if ($4->type != TYPE_CHAR) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-character expression to \"char\" variable.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-character expression to \"char\" variable.");
                                                                }
                                                                value.data.c = $4->data.c;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a variable \"%s\" of type \"%s\" and value: %c\n", $2, $1, value.data.c);
                                                            }
                                                            else if (strcmp($1, "string") == 0) {
                                                                value.type = TYPE_STRING;
                                                                if ($4->type != TYPE_STRING) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-string expression to \"string\" variable.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-string expression to \"string\" variable.");
                                                                }
                                                                value.data.s = $4->data.s;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a variable \"%s\" of type \"%s\" and value: %s\n", $2, $1, value.data.s);
                                                            }
                                                            else {
                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot create a variable of unknown type.", line);
                                                                yyerror("Invalid declaration: cannot create a variable of unknown type.");
                                                            }
                                                            Symbol* symbol = Symbol_construct($2, KIND_VAR, 1, line, value, NULL, 0);
                                                            SymbolTable_insert(symbolTable, symbol);
                                                            writeSymbolToVisualiser(symbol, symbolTable->size);
                                                            lastSymbol = symbol;
                                                            fprintf(quadruplesFile, "(%s, %s, N/A, %s)\n", "=", $4->label, $2);
                                                        }
            | CONST TYPE IDENTIFIER ASSIGN expression   {
                                                            if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                yyerror("Invalid declaration: cannot redeclare symbol.");
                                                            }
                                                            Value value;
                                                            if (strcmp($2, "bool") == 0) {
                                                                value.type = TYPE_BOOL;
                                                                if ($5->type != TYPE_BOOL) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-boolean expression to \"bool\" constant.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-boolean expression to \"bool\" constant.");
                                                                }
                                                                value.data.i = $5->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a constant \"%s\" of type \"%s\" and value: %s\n", $3, $2, value.data.i == 1 ? "true" : "false");
                                                            }
                                                            else if (strcmp($2, "int") == 0) {
                                                                value.type = TYPE_INT;
                                                                if ($5->type != TYPE_INT && $5->type != TYPE_FLOAT) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-numeric expression to \"int\" constant.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"int\" constant.");
                                                                }
                                                                value.data.i = $5->type == TYPE_INT ? $5->data.i : (int) $5->data.f;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a constant \"%s\" of type \"%s\" and value: %d\n", $3, $2, value.data.i);
                                                            }
                                                            else if (strcmp($2, "float") == 0) {
                                                                value.type = TYPE_FLOAT;
                                                                if ($5->type != TYPE_INT && $5->type != TYPE_FLOAT) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-numeric expression to \"float\" constant.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"float\" constant.");
                                                                }
                                                                value.data.f = $5->type == TYPE_FLOAT ? $5->data.f : (float) $5->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a constant \"%s\" of type \"%s\" and value: %f\n", $3, $2, value.data.f);
                                                            }
                                                            else if (strcmp($2, "char") == 0) {
                                                                value.type = TYPE_CHAR;
                                                                if ($5->type != TYPE_CHAR) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-character expression to \"char\" constant.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-character expression to \"char\" constant.");
                                                                }
                                                                value.data.c = $5->data.c;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a constant \"%s\" of type \"%s\" and value: %c\n", $3, $2, value.data.c);
                                                            }
                                                            else if (strcmp($2, "string") == 0) {
                                                                value.type = TYPE_STRING;
                                                                if ($5->type != TYPE_STRING) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign non-string expression to \"string\" constant.", line);
                                                                    yyerror("Invalid assignment: cannot assign non-string expression to \"string\" constant.");
                                                                }
                                                                value.data.s = $5->data.s;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    fprintf(symbolTableFile, "    ");
                                                                    fprintf(symbolTableVisualiser, "    ");
                                                                }
                                                                fprintf(symbolTableFile, "Declared a constant \"%s\" of type \"%s\" and value: %s\n", $3, $2, value.data.s);
                                                            }
                                                            else {
                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot create a constant of unknown type.", line);
                                                                yyerror("Invalid declaration: cannot create a constant of unknown type.");
                                                            }
                                                            Symbol* symbol = Symbol_construct($3, KIND_CONST, 1, line, value, NULL, 0);
                                                            SymbolTable_insert(symbolTable, symbol);
                                                            writeSymbolToVisualiser(symbol, symbolTable->size);
                                                            lastSymbol = symbol;
                                                            fprintf(quadruplesFile, "(%s, %s, N/A, %s)\n", "=", $5->label, $3);
                                                        }
            ;

assignment : IDENTIFIER ASSIGN expression   {
                                                Symbol* var = SymbolTable_get(symbolTable, $1);
                                                if (!var) {
                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot find symbol.", line);
                                                    yyerror("Invalid expression: cannot find symbol.");
                                                }
                                                if (var->kind == KIND_FUNC || var->kind == KIND_CONST) {
                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: cannot assign to a constant or a function.", line);
                                                    yyerror("Invalid assignment: cannot assign to a constant or a function.");
                                                }
                                                if ((($3->type == TYPE_INT || $3->type == TYPE_FLOAT) && (var->value.type != TYPE_INT && var->value.type != TYPE_FLOAT)) || (($3->type == TYPE_BOOL || $3->type == TYPE_STRING || $3->type == TYPE_CHAR) && ($3->type != var->value.type))) {
                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid assignment: type of variable does not match type of expression.", line);
                                                    yyerror("Invalid assignment: type of variable does not match type of expression.");
                                                }
                                                switch (var->value.type) {
                                                    case TYPE_BOOL:
                                                        var->value.data.i = $3->data.i;
                                                        break;
                                                    case TYPE_INT:
                                                        var->value.data.i = ($3->type == TYPE_INT) ? $3->data.i : (int) $3->data.f;
                                                        break;
                                                    case TYPE_FLOAT:
                                                        var->value.data.f = ($3->type == TYPE_FLOAT) ? $3->data.f : (float) $3->data.i;
                                                        break;
                                                    case TYPE_CHAR:
                                                        var->value.data.c = $3->data.c;
                                                        break;
                                                    case TYPE_STRING:
                                                        var->value.data.s = $3->data.s;
                                                        break;
                                                }
                                                fprintf(quadruplesFile, "(%s, %s, N/A, %s)\n", "=", $3->label, $1);
                                            }
           ;

decision : expression   {
                            if ($1->type != TYPE_BOOL) {
                                fprintf(semanticAnalysisFile, "Line %d: Invalid statement: cannot use a non-boolean expression as a decision expression.", line);
                                yyerror("Invalid statement: cannot use a non-boolean expression as a decision expression.");
                            }
                            $$ = $1;
                        }

iterator : expression   {
                            if ($1->type != TYPE_INT) {
                                fprintf(semanticAnalysisFile, "Line %d: Invalid statement: cannot use a non-integer expression as an iterator expression.", line);
                                yyerror("Invalid statement: cannot use a non-integer expression as an iterator expression.");
                            }
                            $$ = $1;
                        }

if_header : IF OPENING_PARENTHESIS decision CLOSING_PARENTHESIS {
                                                                    labelNames[labelDepth] = malloc(20);
                                                                    sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                    labels++;
                                                                    labelDepth++;
                                                                    labelNames[labelDepth] = malloc(20);
                                                                    sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                    fprintf(quadruplesFile, "(JZ, LABEL%d, N/A, N/A)\n", labels);
                                                                    labels++;
                                                                    labelDepth++;
                                                                }
          ;

if_statement : if_header block      {
                                        fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 1]);
                                        labelDepth--;
                                        labelDepth--;
                                    }
             | if_header block ELSE {
                                        fprintf(quadruplesFile, "(JMP, %s, N/A, N/A)\n", labelNames[labelDepth - 2]);
                                        fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 1]);
                                    }
               block                {
                                        fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 2]);
                                        labelDepth--;
                                        labelDepth--;
                                    }
             ;

switch_header : SWITCH OPENING_PARENTHESIS expression CLOSING_PARENTHESIS   {
                                                                                switchExpr[switchDepth] = malloc(sizeof(Value));
                                                                                switchExpr[switchDepth] = $3;
                                                                                switchLabel[switchDepth] = labelDepth;
                                                                                switchDepth++;
                                                                                labelNames[labelDepth] = malloc(20);
                                                                                sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                                labelDepth++;
                                                                                labels++;
                                                                                $$ = $3;
                                                                            }
              ;

switch_statement : switch_header SCOPE_START case_statements SCOPE_END              {
                                                                                        for (int i = 0; i < numCases[switchDepth]; i++) {
                                                                                            if ($1->type != ($3)[i]->type) {
                                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid case statement: type of expression inside the switch statement does not match the types of expressions inside the case statements.", line);
                                                                                                yyerror("Invalid case statement: type of expression inside the switch statement does not match the types of expressions inside the case statements.");
                                                                                            }
                                                                                        }
                                                                                        switchDepth--;
                                                                                        labelDepth--;
                                                                                        fprintf(quadruplesFile, "%s:\n", labelNames[switchLabel[switchDepth]]);
                                                                                    }
                 | switch_header SCOPE_START case_statements default_case SCOPE_END {
                                                                                        for (int i = 0; i < numCases[switchDepth]; i++) {
                                                                                            if ($1->type != ($3)[i]->type) {
                                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid case statement: type of expression inside the switch statement does not match the types of expressions inside the case statements.", line);
                                                                                                yyerror("Invalid case statement: type of expression inside the switch statement does not match the types of expressions inside the case statements.");
                                                                                            }
                                                                                        }
                                                                                        switchDepth--;
                                                                                        labelDepth--;
                                                                                        fprintf(quadruplesFile, "%s:\n", labelNames[switchLabel[switchDepth]]);
                                                                                    }
                 ;

case_statements : case_statements case_statement    {
                                                        numCases[switchDepth] = numCases[switchDepth] + 1;
                                                        $$ = malloc(numCases[switchDepth] * sizeof(Value*));
                                                        for (int i = 0; i < numCases[switchDepth] - 1; i++) {
                                                            ($$)[i] = ($1)[i];
                                                        }
                                                        ($$)[numCases[switchDepth] - 1] = $2;
                                                    }
                | case_statement                    {
                                                        numCases[switchDepth] = 1;
                                                        $$ = malloc(sizeof(Value*));
                                                        ($$)[0] = $1;
                                                    }
                ;

case_header : CASE OPENING_PARENTHESIS expression CLOSING_PARENTHESIS   {
                                                                            $$ = $3;
                                                                            char* temp = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(==, %s, %s, %s)\n", switchExpr[switchDepth - 1]->label, $3->label, temp);
                                                                            labelNames[labelDepth] = malloc(20);
                                                                            sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                            fprintf(quadruplesFile, "(JZ, LABEL%d, N/A, N/A)\n", labels);
                                                                            labelDepth++;
                                                                            labels++;
                                                                        }

case_statement : case_header block  {
                                        $$ = $1;
                                        fprintf(quadruplesFile, "(JMP, %s, N/A, N/A)\n", labelNames[switchLabel[switchDepth - 1]]);
                                        fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 1]);
                                        labelDepth--;
                                    }
               ;

default_case : DEFAULT block
             ;

for_from : FOR IDENTIFIER FROM OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS {
                                                                                    Symbol* var = SymbolTable_get(symbolTable, $2);
                                                                                    if (!var) {
                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot find symbol.", line);
                                                                                        yyerror("Invalid expression: cannot find symbol.");
                                                                                    }
                                                                                    if (var->kind == KIND_FUNC || var->kind == KIND_CONST) {
                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid statemen: cannot use a constant or a function as a for loop iterator.", line);
                                                                                        yyerror("Invalid statemen: cannot use a constant or a function as a for loop iterator.");
                                                                                    }
                                                                                    if (var->value.type != TYPE_INT) {
                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid statement: cannot use a non-integer variable as a for loop iterator.", line);
                                                                                        yyerror("Invalid statement: cannot use a non-integer variable as a for loop iterator.");
                                                                                    }
                                                                                    var->isUsed = 1;
                                                                                    fprintf(quadruplesFile, "(=, %s, N/A, %s)\n", $5->label, $2);
                                                                                    labelNames[labelDepth] = malloc(20);
                                                                                    sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                                    fprintf(quadruplesFile, "LABEL%d:\n", labels);
                                                                                    labelDepth++;
                                                                                    labels++;
                                                                                    forIterator[forDepth] = malloc(50);
                                                                                    strcpy(forIterator[forDepth], var->name);
                                                                                    forDepth++;
                                                                                }
         ;

for_to : TO OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS    {
                                                                    char* temp = addTempVar(&tempVars);
                                                                    fprintf(quadruplesFile, "(<, %s, %s, %s)\n", forIterator[forDepth - 1], $3->label, temp);
                                                                    labelNames[labelDepth] = malloc(20);
                                                                    sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                    fprintf(quadruplesFile, "(JZ, LABEL%d, N/A, N/A)\n", labels);
                                                                    labelDepth++;
                                                                    labels++;
                                                                }
       ;

for_loop : for_from for_to block                                                        {
                                                                                            forDepth--;
                                                                                            char* temp = addTempVar(&tempVars);
                                                                                            fprintf(quadruplesFile, "(+, %s, 1, %s)\n", forIterator[forDepth], temp);
                                                                                            fprintf(quadruplesFile, "(JMP, %s, N/A, N/A)\n", labelNames[labelDepth - 2]);
                                                                                            fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 1]);
                                                                                            labelDepth--;
                                                                                            labelDepth--;
                                                                                        }
         | for_from for_to STEP OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS block  {
                                                                                            forDepth--;
                                                                                            char* temp = addTempVar(&tempVars);
                                                                                            fprintf(quadruplesFile, "(+, %s, %s, %s)\n", forIterator[forDepth], $5->label, temp);
                                                                                            fprintf(quadruplesFile, "(JMP, %s, N/A, N/A)\n", labelNames[labelDepth - 2]);
                                                                                            fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 1]);
                                                                                            labelDepth--;
                                                                                            labelDepth--;
                                                                                        }
         ;

while_header : WHILE            {
                                    labelNames[labelDepth] = malloc(20);
                                    sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                    fprintf(quadruplesFile, "LABEL%d:\n", labels);
                                    labelDepth++;
                                    labels++;
                                }
               while_expression
             ;

while_expression : OPENING_PARENTHESIS decision CLOSING_PARENTHESIS {
                                                                        labelNames[labelDepth] = malloc(20);
                                                                        sprintf(labelNames[labelDepth], "LABEL%d", labels);
                                                                        fprintf(quadruplesFile, "(JZ, LABEL%d, N/A, N/A)\n", labels);
                                                                        labelDepth++;
                                                                        labels++;
                                                                    }
                 ;

while_loop : while_header block {
                                    fprintf(quadruplesFile, "(JMP, %s, N/A, N/A)\n", labelNames[labelDepth - 2]);
                                    fprintf(quadruplesFile, "%s:\n", labelNames[labelDepth - 1]);
                                    labelDepth--;
                                    labelDepth--;
                                }
           ;

repeat_loop : REPEAT block UNTIL OPENING_PARENTHESIS decision CLOSING_PARENTHESIS
            ;

function_declaration : VOID IDENTIFIER OPENING_PARENTHESIS parameter_list CLOSING_PARENTHESIS   {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    value.type = TYPE_VOID;
                                                                                                    value.data.i = 0;
                                                                                                    for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                        fprintf(symbolTableFile, "    ");
                                                                                                    }
                                                                                                    fprintf(symbolTableFile, "Declared a function \"%s\" of type \"void\" with %d parameters.\n", $2, numParams);
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, line, value, $4, numParams);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    writeSymbolToVisualiser(symbol, symbolTable->size);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     | TYPE IDENTIFIER OPENING_PARENTHESIS parameter_list CLOSING_PARENTHESIS   {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    if (strcmp($1, "bool") == 0) {
                                                                                                        value.type = TYPE_BOOL;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "int") == 0) {
                                                                                                        value.type = TYPE_INT;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "float") == 0) {
                                                                                                        value.type = TYPE_FLOAT;
                                                                                                        value.data.f = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "char") == 0) {
                                                                                                        value.type = TYPE_CHAR;
                                                                                                        value.data.c = '0';
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "string") == 0) {
                                                                                                        value.type = TYPE_STRING;
                                                                                                        value.data.s = "";
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else {
                                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot create a function of unknown type.", line);
                                                                                                        yyerror("Invalid declaration: cannot create a function of unknown type.");
                                                                                                    }
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, line, value, $4, numParams);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    writeSymbolToVisualiser(symbol, symbolTable->size);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     | VOID IDENTIFIER OPENING_PARENTHESIS CLOSING_PARENTHESIS                  {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    value.type = TYPE_VOID;
                                                                                                    value.data.i = 0;
                                                                                                    for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                        fprintf(symbolTableFile, "    ");
                                                                                                    }
                                                                                                    fprintf(symbolTableFile, "Declared a function \"%s\" of type \"void\"\n", $2);
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, line, value, NULL, 0);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    writeSymbolToVisualiser(symbol, symbolTable->size);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     | TYPE IDENTIFIER OPENING_PARENTHESIS CLOSING_PARENTHESIS                  {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot redeclare symbol.", line);
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    if (strcmp($1, "bool") == 0) {
                                                                                                        value.type = TYPE_BOOL;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "int") == 0) {
                                                                                                        value.type = TYPE_INT;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "float") == 0) {
                                                                                                        value.type = TYPE_FLOAT;
                                                                                                        value.data.f = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "char") == 0) {
                                                                                                        value.type = TYPE_CHAR;
                                                                                                        value.data.c = '0';
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "string") == 0) {
                                                                                                        value.type = TYPE_STRING;
                                                                                                        value.data.s = "";
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            fprintf(symbolTableFile, "    ");
                                                                                                        }
                                                                                                        fprintf(symbolTableFile, "Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else {
                                                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot create a function of unknown type.", line);
                                                                                                        yyerror("Invalid declaration: cannot create a function of unknown type.");
                                                                                                    }
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, line, value, NULL, 0);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    writeSymbolToVisualiser(symbol, symbolTable->size);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     ;

parameter_list : parameter_list COMMA parameter {
                                                    numParams = numParams + 1;
                                                    $$ = malloc(numParams * sizeof(Symbol*));
                                                    for (int i = 0; i < numParams - 1; i++) {
                                                        ($$)[i] = ($1)[i];
                                                    }
                                                    ($$)[numParams - 1] = $3;
                                                }
               | parameter                      {
                                                    numParams = 1;
                                                    $$ = malloc(sizeof(Symbol*));
                                                    ($$)[0] = $1;
                                                }
               ;

parameter : TYPE IDENTIFIER {
                                Value value;
                                if (strcmp($1, "bool") == 0) {
                                    value.type = TYPE_BOOL;
                                    value.data.i = 0;
                                }
                                else if (strcmp($1, "int") == 0) {
                                    value.type = TYPE_INT;
                                    value.data.i = 0;
                                }
                                else if (strcmp($1, "float") == 0) {
                                    value.type = TYPE_FLOAT;
                                    value.data.f = 0;
                                }
                                else if (strcmp($1, "char") == 0) {
                                    value.type = TYPE_CHAR;
                                    value.data.c = '0';
                                }
                                else if (strcmp($1, "string") == 0) {
                                    value.type = TYPE_STRING;
                                    value.data.s = "";
                                }
                                else {
                                    fprintf(semanticAnalysisFile, "Line %d: Invalid declaration: cannot create a parameter of unknown type.", line);
                                    yyerror("Invalid declaration: cannot create a parameter of unknown type.");
                                }
                                $$ = Symbol_construct($2, KIND_VAR, 1, line, value, NULL, 0);
                            }
          ;

return_statement : RETURN expression    {
                                            if (!currFunc) {
                                                fprintf(semanticAnalysisFile, "Line %d: Invalid statement: cannot use a return statement outside a function.", line);
                                                yyerror("Invalid statement: cannot use a return statement outside a function.");
                                            }
                                            if (currFunc->value.type == TYPE_VOID) {
                                                fprintf(semanticAnalysisFile, "Line %d: Invalid statement: cannot use a return statement in a \"void\" function.", line);
                                                yyerror("Invalid statement: cannot use a return statement in a \"void\" function.");
                                            }
                                            if ($2->type != currFunc->value.type) {
                                                fprintf(semanticAnalysisFile, "Line %d: Invalid statement: returned expression does not match function return type.", line);
                                                yyerror("Invalid statement: returned expression does not match function return type.");
                                            }
                                        }
                 ;

function_call : IDENTIFIER OPENING_PARENTHESIS argument_list CLOSING_PARENTHESIS    {
                                                                                        Symbol* func = SymbolTable_get(symbolTable, $1);
                                                                                        if (!func) {
                                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot find symbol.", line);
                                                                                            yyerror("Invalid expression: cannot find symbol.");
                                                                                        }
                                                                                        if (func->kind == KIND_VAR || func->kind == KIND_CONST) {
                                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot use a variable or constant as a function.", line);
                                                                                            yyerror("Invalid expression: cannot use a variable or constant as a function.");
                                                                                        }
                                                                                        if (numArgs != func->numParams) {
                                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: number of arguments is not equal to number of parameters.", line);
                                                                                            yyerror("Invalid expression: number of arguments is not equal to number of parameters.");
                                                                                        }
                                                                                        for (int i = 0; i < numArgs; i++) {
                                                                                            Symbol* param = func->params[i];
                                                                                            if (($3)[i]->type != param->value.type) {
                                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: types of arguments do not match types of parameters.", line);
                                                                                                yyerror("Invalid expression: types of arguments do not match types of parameters.");
                                                                                            }
                                                                                        }
                                                                                        $$ = malloc(sizeof(Value));
                                                                                        $$->type = func->value.type;
                                                                                        switch ($$->type) {
                                                                                            case TYPE_BOOL:
                                                                                                $$->data.i = func->value.data.i;
                                                                                                break;
                                                                                            case TYPE_INT:
                                                                                                $$->data.i = func->value.data.i;
                                                                                                break;
                                                                                            case TYPE_FLOAT:
                                                                                                $$->data.f = func->value.data.f;
                                                                                                break;
                                                                                            case TYPE_CHAR:
                                                                                                $$->data.c = func->value.data.c;
                                                                                                break;
                                                                                            case TYPE_STRING:
                                                                                                $$->data.s = func->value.data.s;
                                                                                                break;
                                                                                            case TYPE_VOID:
                                                                                                $$->data.i = 0;
                                                                                                break;
                                                                                        }
                                                                                        func->isUsed = 1;
                                                                                    }
              | IDENTIFIER OPENING_PARENTHESIS CLOSING_PARENTHESIS                  {
                                                                                        Symbol* func = SymbolTable_get(symbolTable, $1);
                                                                                        if (!func) {
                                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot find symbol.", line);
                                                                                            yyerror("Invalid expression: cannot find symbol.");
                                                                                        }
                                                                                        if (func->kind == KIND_VAR || func->kind == KIND_CONST) {
                                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot use a variable or constant as a function.", line);
                                                                                            yyerror("Invalid expression: cannot use a variable or constant as a function.");
                                                                                        }
                                                                                        $$ = malloc(sizeof(Value));
                                                                                        $$->type = func->value.type;
                                                                                        switch ($$->type) {
                                                                                            case TYPE_BOOL:
                                                                                                $$->data.i = func->value.data.i;
                                                                                                break;
                                                                                            case TYPE_INT:
                                                                                                $$->data.i = func->value.data.i;
                                                                                                break;
                                                                                            case TYPE_FLOAT:
                                                                                                $$->data.f = func->value.data.f;
                                                                                                break;
                                                                                            case TYPE_CHAR:
                                                                                                $$->data.c = func->value.data.c;
                                                                                                break;
                                                                                            case TYPE_STRING:
                                                                                                $$->data.s = func->value.data.s;
                                                                                                break;
                                                                                            case TYPE_VOID:
                                                                                                $$->data.i = 0;
                                                                                                break;
                                                                                        }
                                                                                        func->isUsed = 1;
                                                                                    }
              ;

argument_list : argument_list COMMA argument    {
                                                    numArgs = numArgs + 1;
                                                    $$ = malloc(numArgs * sizeof(Value*));
                                                    for (int i = 0; i < numArgs - 1; i++) {
                                                        ($$)[i] = ($1)[i];
                                                    }
                                                    ($$)[numArgs - 1] = $3;
                                                }
              | argument                        {
                                                    numArgs = 1;
                                                    $$ = malloc(sizeof(Value*));
                                                    ($$)[0] = $1;
                                                }
              ;

argument : expression   {
                            $$ = $1;
                        }
         ;

expression : logical_expression {
                                    $$ = $1;
                                }
           ;

logical_expression : logical_expression OR logical_conjunction  {
                                                                    if ($1->type != TYPE_BOOL || $3->type != TYPE_BOOL) {
                                                                        fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a disjunction operation between non-boolean expressions.", line);
                                                                        yyerror("Invalid expression: cannot perform a disjunction operation between non-boolean expressions.");
                                                                    }
                                                                    $$ = malloc(sizeof(Value));
                                                                    $$->type = TYPE_BOOL;
                                                                    $$->data.i = $1->data.i || $3->data.i;
                                                                    $$->label = addTempVar(&tempVars);
                                                                    fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "|", $1->label, $3->label, $$->label);
                                                                }
                   | logical_conjunction                        {
                                                                    $$ = $1;
                                                                }
                   ;

logical_conjunction : logical_conjunction AND logical_comparison    {
                                                                        if ($1->type != TYPE_BOOL || $3->type != TYPE_BOOL) {
                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a conjunction operation between non-boolean expressions.", line);
                                                                            yyerror("Invalid expression: cannot perform a conjunction operation between non-boolean expressions.");
                                                                        }
                                                                        $$ = malloc(sizeof(Value));
                                                                        $$->type = TYPE_BOOL;
                                                                        $$->data.i = $1->data.i && $3->data.i;
                                                                        $$->label = addTempVar(&tempVars);
                                                                        fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "&", $1->label, $3->label, $$->label);
                                                                    }
                    | logical_comparison                            {
                                                                        $$ = $1;
                                                                    }
                    ;

logical_comparison : logical_comparison EQ mathematical_expression      {
                                                                            if ($1->type == TYPE_BOOL && $3->type == TYPE_BOOL) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.i == $3->data.i;
                                                                            }
                                                                            else if (($1->type == TYPE_INT || $1->type == TYPE_FLOAT) && ($3->type == TYPE_INT || $3->type == TYPE_FLOAT)) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = ($1->type == TYPE_INT ? $1->data.i : $1->data.f) == ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                            }
                                                                            else if ($1->type == TYPE_CHAR && $3->type == TYPE_CHAR) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.c == $3->data.c;
                                                                            }
                                                                            else if ($1->type == TYPE_STRING && $3->type == TYPE_STRING) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = strcmp($1->data.s, $3->data.s) == 0;
                                                                            }
                                                                            else {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot compare between different-typed expressions.", line);
                                                                                yyerror("Invalid expression: cannot compare between different-typed expressions.");
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "==", $1->label, $3->label, $$->label);
                                                                        }
                   | logical_comparison NE mathematical_expression      {
                                                                            if ($1->type == TYPE_BOOL && $3->type == TYPE_BOOL) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.i != $3->data.i;
                                                                            }
                                                                            else if (($1->type == TYPE_INT || $1->type == TYPE_FLOAT) && ($3->type == TYPE_INT || $3->type == TYPE_FLOAT)) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = ($1->type == TYPE_INT ? $1->data.i : $1->data.f) != ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                            }
                                                                            else if ($1->type == TYPE_CHAR && $3->type == TYPE_CHAR) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.c != $3->data.c;
                                                                            }
                                                                            else if ($1->type == TYPE_STRING && $3->type == TYPE_STRING) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = strcmp($1->data.s, $3->data.s) != 0;
                                                                            }
                                                                            else {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot compare between different-typed expressions.", line);
                                                                                yyerror("Invalid expression: cannot compare between different-typed expressions.");
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "!=", $1->label, $3->label, $$->label);
                                                                        }
                   | mathematical_expression LT mathematical_expression {
                                                                            if (($1->type == TYPE_INT || $1->type == TYPE_FLOAT) && ($3->type == TYPE_INT || $3->type == TYPE_FLOAT)) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = ($1->type == TYPE_INT ? $1->data.i : $1->data.f) < ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                            }
                                                                            else if ($1->type == TYPE_CHAR && $3->type == TYPE_CHAR) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.c < $3->data.c;
                                                                            }
                                                                            else {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.", line);
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "<", $1->label, $3->label, $$->label);
                                                                        }
                   | mathematical_expression GT mathematical_expression {
                                                                            if (($1->type == TYPE_INT || $1->type == TYPE_FLOAT) && ($3->type == TYPE_INT || $3->type == TYPE_FLOAT)) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = ($1->type == TYPE_INT ? $1->data.i : $1->data.f) > ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                            }
                                                                            else if ($1->type == TYPE_CHAR && $3->type == TYPE_CHAR) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.c > $3->data.c;
                                                                            }
                                                                            else {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.", line);
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", ">", $1->label, $3->label, $$->label);
                                                                        }
                   | mathematical_expression LE mathematical_expression {
                                                                            if (($1->type == TYPE_INT || $1->type == TYPE_FLOAT) && ($3->type == TYPE_INT || $3->type == TYPE_FLOAT)) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = ($1->type == TYPE_INT ? $1->data.i : $1->data.f) <= ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                            }
                                                                            else if ($1->type == TYPE_CHAR && $3->type == TYPE_CHAR) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.c <= $3->data.c;
                                                                            }
                                                                            else {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.", line);
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "<=", $1->label, $3->label, $$->label);
                                                                        }
                   | mathematical_expression GE mathematical_expression {
                                                                            if (($1->type == TYPE_INT || $1->type == TYPE_FLOAT) && ($3->type == TYPE_INT || $3->type == TYPE_FLOAT)) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = ($1->type == TYPE_INT ? $1->data.i : $1->data.f) >= ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                            }
                                                                            else if ($1->type == TYPE_CHAR && $3->type == TYPE_CHAR) {
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = TYPE_BOOL;
                                                                                $$->data.i = $1->data.c >= $3->data.c;
                                                                            }
                                                                            else {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.", line);
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", ">=", $1->label, $3->label, $$->label);
                                                                        }
                   | mathematical_expression                            {
                                                                            $$ = $1;
                                                                        }
                   ;

mathematical_expression : mathematical_expression PLUS mathematical_term    {
                                                                                if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
                                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform an addition operation between non-numeric expressions.", line);
                                                                                    yyerror("Invalid expression: cannot perform an addition operation between non-numeric expressions.");
                                                                                }
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
                                                                                if ($$->type == TYPE_INT) {
                                                                                    $$->data.i = $1->data.i - $3->data.i;
                                                                                }
                                                                                else {
                                                                                    $$->data.f = (float) ($1->type == TYPE_INT ? $1->data.i : $1->data.f) + ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                                }
                                                                                $$->label = addTempVar(&tempVars);
                                                                                fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "+", $1->label, $3->label, $$->label);
                                                                            }
                        | mathematical_expression MINUS mathematical_term   {
                                                                                if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
                                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a subtraction operation between non-numeric expressions.", line);
                                                                                    yyerror("Invalid expression: cannot perform a subtraction operation between non-numeric expressions.");
                                                                                }
                                                                                $$ = malloc(sizeof(Value));
                                                                                $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
                                                                                if ($$->type == TYPE_INT) {
                                                                                    $$->data.i = $1->data.i - $3->data.i;
                                                                                }
                                                                                else {
                                                                                    $$->data.f = (float) ($1->type == TYPE_INT ? $1->data.i : $1->data.f) - ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                                }
                                                                                $$->label = addTempVar(&tempVars);
                                                                                fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "-", $1->label, $3->label, $$->label);
                                                                            }
                        | mathematical_term                                 {
                                                                                $$ = $1;
                                                                            }
                        ;

mathematical_term : mathematical_term MULT mathematical_exponent    {
                                                                        if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a multiplication operation between non-numeric expressions.", line);
                                                                            yyerror("Invalid expression: cannot perform a multiplication operation between non-numeric expressions.");
                                                                        }
                                                                        $$ = malloc(sizeof(Value));
                                                                        $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
                                                                        if ($$->type == TYPE_INT) {
                                                                            $$->data.i = $1->data.i * $3->data.i;
                                                                        }
                                                                        else {
                                                                            $$->data.f = (float) ($1->type == TYPE_INT ? $1->data.i : $1->data.f) * ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                        }
                                                                        $$->label = addTempVar(&tempVars);
                                                                        fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "*", $1->label, $3->label, $$->label);
                                                                    }
                  | mathematical_term DIV mathematical_exponent     {
                                                                        if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a division operation between non-numeric expressions.", line);
                                                                            yyerror("Invalid expression: cannot perform a division operation between non-numeric expressions.");
                                                                        }
                                                                        if (($3->type == TYPE_INT && $3->data.i == 0) || ($3->type == TYPE_FLOAT && $3->data.f == 0)) {
                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot divide by zero.", line);
                                                                            yyerror("Invalid expression: cannot divide by zero.");
                                                                        }
                                                                        $$ = malloc(sizeof(Value));
                                                                        $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT) ? TYPE_FLOAT : TYPE_INT;
                                                                        if ($$->type == TYPE_INT) {
                                                                            $$->data.i = $1->data.i / $3->data.i;
                                                                        }
                                                                        else {
                                                                            $$->data.f = (float) ($1->type == TYPE_INT ? $1->data.i : $1->data.f) / ($3->type == TYPE_INT ? $3->data.i : $3->data.f);
                                                                        }
                                                                        $$->label = addTempVar(&tempVars);
                                                                        fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "/", $1->label, $3->label, $$->label);
                                                                    }
                  | mathematical_term MOD mathematical_exponent     {
                                                                        if ($1->type != TYPE_INT || $3->type != TYPE_INT) {
                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a remainder operation between non-integer expressions.", line);
                                                                            yyerror("Invalid expression: cannot perform a remainder operation between non-integer expressions.");
                                                                        }
                                                                        if ($3->data.i == 0) {
                                                                            fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot divide by zero.", line);
                                                                            yyerror("Invalid expression: cannot divide by zero.");
                                                                        }
                                                                        $$ = malloc(sizeof(Value));
                                                                        $$->type = TYPE_INT;
                                                                        $$->data.i = $1->data.i % $3->data.i;
                                                                        $$->label = addTempVar(&tempVars);
                                                                        fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "%", $1->label, $3->label, $$->label);
                                                                    }
                  | mathematical_exponent                           {
                                                                        $$ = $1;
                                                                    }
                  ;

mathematical_exponent : primary POW mathematical_exponent   {
                                                                if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
                                                                    fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform an exponentiation operation between non-numeric expressions.", line);
                                                                    yyerror("Invalid expression: cannot perform an exponentiation operation between non-numeric expressions.");
                                                                }
                                                                $$ = malloc(sizeof(Value));
                                                                $$->type = ($1->type == TYPE_FLOAT || $3->type == TYPE_FLOAT || (($3->type == TYPE_INT) && ($3->data.i < 0))) ? TYPE_FLOAT : TYPE_INT;
                                                                if ($$->type == TYPE_INT) {
                                                                    $$->data.i = pow($1->data.i, $3->data.i);
                                                                }
                                                                else {
                                                                    $$->data.f = pow(($1->type == TYPE_INT ? $1->data.i : $1->data.f), ($3->type == TYPE_INT ? $3->data.i : $3->data.f));
                                                                }
                                                                $$->label = addTempVar(&tempVars);
                                                                fprintf(quadruplesFile, "(%s, %s, %s, %s)\n", "^", $1->label, $3->label, $$->label);
                                                            }
                      | primary                             {
                                                                $$ = $1;
                                                            }
                      ;

primary : OPENING_PARENTHESIS logical_expression CLOSING_PARENTHESIS    {
                                                                            $$ = $2;
                                                                        }
        | MINUS primary                                                 {
                                                                            if ($2->type != TYPE_INT && $2->type != TYPE_FLOAT) {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform a negation operation on a non-numeric expression.", line);
                                                                                yyerror("Invalid expression: cannot perform a negation operation on a non-numeric expression.");
                                                                            }
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = $2->type;
                                                                            if ($$->type == TYPE_INT) {
                                                                                $$->data.i = -($2->data.i);
                                                                            }
                                                                            else {
                                                                                $$->data.f = -($2->data.f);
                                                                            }
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, N/A, %s)\n", "-", $2->label, $$->label);
                                                                        }
        | NOT primary                                                   {
                                                                            if ($2->type != TYPE_BOOL) {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot perform an inversion operation on a non-boolean expression.", line);
                                                                                yyerror("Invalid expression: cannot perform an inversion operation on a non-boolean expression.");
                                                                            }
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_BOOL;
                                                                            $$->data.i = !($2->data.i);
                                                                            $$->label = addTempVar(&tempVars);
                                                                            fprintf(quadruplesFile, "(%s, %s, N/A, %s)\n", "!", $2->label, $$->label);
                                                                        }
        | INTEGER                                                       {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_INT;
                                                                            $$->data.i = $1;
                                                                            int size = snprintf(NULL, 0, "%d", $1);
                                                                            $$->label = malloc(size + 1);
                                                                            sprintf($$->label, "%d", $1);
                                                                        }
        | FLOAT                                                         {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_FLOAT;
                                                                            $$->data.f = $1;
                                                                            int size = snprintf(NULL, 0, "%f", $1);
                                                                            $$->label = malloc(size + 1);
                                                                            sprintf($$->label, "%f", $1);
                                                                        }
        | BOOL                                                          {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_BOOL;
                                                                            $$->data.i = $1;
                                                                            $$->label = malloc($1 == 1 ? 5 : 6);
                                                                            strcpy($$->label, $1 == 1 ? "true" : "false");
                                                                        }
        | CHAR                                                          {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_CHAR;
                                                                            $$->data.c = $1;
                                                                            $$->label = malloc(4);
                                                                            sprintf($$->label, "'%c'", $1);
                                                                        }
        | STRING                                                        {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_STRING;
                                                                            $$->data.s = $1;
                                                                            $$->label = malloc(strlen($1) + 3);
                                                                            strcpy($$->label + 1, $1);
                                                                            $$->label[0] = '"';
                                                                            $$->label[strlen($1) + 1] = '"';
                                                                        }
        | IDENTIFIER                                                    {
                                                                            $$ = malloc(sizeof(Value));
                                                                            Symbol* symbol = SymbolTable_get(symbolTable, $1);
                                                                            if (!symbol) {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot find symbol.", line);
                                                                                yyerror("Invalid expression: cannot find symbol.");
                                                                            }
                                                                            if (symbol->kind != KIND_VAR && symbol->kind != KIND_CONST) {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot call function without argument list.", line);
                                                                                yyerror("Invalid expression: cannot call function without argument list.");
                                                                            }
                                                                            if (!(symbol->isInit)) {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot use an uninitialized variable.", line);
                                                                                yyerror("Invalid expression: cannot use an uninitialized variable.");
                                                                            }
                                                                            $$->type = symbol->value.type;
                                                                            switch($$->type) {
                                                                                case TYPE_BOOL:
                                                                                    $$->data.i = symbol->value.data.i;
                                                                                    break;
                                                                                case TYPE_INT:
                                                                                    $$->data.i = symbol->value.data.i;
                                                                                    break;
                                                                                case TYPE_FLOAT:
                                                                                    $$->data.f = symbol->value.data.f;
                                                                                    break;
                                                                                case TYPE_CHAR:
                                                                                    $$->data.c = symbol->value.data.c;
                                                                                    break;
                                                                                case TYPE_STRING:
                                                                                    $$->data.s = symbol->value.data.s;
                                                                                    break;
                                                                            }
                                                                            symbol->isUsed = 1;
                                                                            $$->label = malloc(sizeof($1) + 1);
                                                                            strcpy($$->label, $1);
                                                                        }
        | function_call                                                 {
                                                                            if ($1->type == TYPE_VOID) {
                                                                                fprintf(semanticAnalysisFile, "Line %d: Invalid expression: cannot call a \"void\" function.", line);
                                                                                yyerror("Invalid expression: cannot call a \"void\" function.");
                                                                            }
                                                                            $$ = $1;
                                                                        }
        ;

print_statement : PRINT OPENING_PARENTHESIS argument_list CLOSING_PARENTHESIS
                | PRINT OPENING_PARENTHESIS CLOSING_PARENTHESIS
                ;

%%

/* Subroutines */
void yyerror(const char* s) {
    fprintf(stderr, "\nLine %d: %s\n", line, s);
    if (symbolTableFile) {
        fclose(symbolTableFile);
    }
    if (semanticAnalysisFile) {
        fclose(semanticAnalysisFile);
    }
    if (quadruplesFile) {
        fclose(quadruplesFile);
    }
    exit(1);
}

int main(int argc, char** argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            fprintf(stderr, "Error opening file: %s\n", argv[1]);
            return 1;
        }
    } else {
        yyin = stdin;
    }

    symbolTableFile = fopen("SymbolTable.out", "w");
    if (symbolTableFile == NULL) {
        printf("Error opening SymbolTable.out.");
        return 1;
    }

    semanticAnalysisFile = fopen("SemanticAnalysis.out", "w");
    if (semanticAnalysisFile == NULL) {
        printf("Error opening SemanticAnalysis.out.");
        return 1;
    }

    symbolTableVisualiser = fopen("SymbolTableVisualiser.out", "w");
    if (symbolTableVisualiser == NULL) {
        printf("Error opening SymbolTableVisualiser.out.");
        return 1;
    }
    fprintf(symbolTableVisualiser, "Symbol table for global scope.\n");
    fprintf(symbolTableVisualiser, "| %-12s | %-9s | %-12s | %-6s | %-17s |\n", "name", "kind", "value", "type", "declaration line");
    fprintf(symbolTableVisualiser, "------------------------------------------------------------------------\n");

    quadruplesFile = fopen("Quadruples.out", "w");
    if (quadruplesFile == NULL) {
        printf("Error opening Quadruples.out.");
        return 1;
    }
    for (int i = 0; i < 100; i++) {
        numCases[i] = 0;
    }
    
    symbolTable = SymbolTable_construct();

    yyparse();
    fclose(yyin);

    SymbolTable_destroy(symbolTable);
    fclose(symbolTableFile);
    fclose(semanticAnalysisFile);
    fclose(symbolTableVisualiser);
    fclose(quadruplesFile);
    
    return 0;
}