/* Definitions */
%{
    #include "globals.h"

    void yyerror(const char* s);
    int yylex(void);
    extern FILE* yyin;
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
%type <v> expression mathematical_expression mathematical_term mathematical_exponent logical_expression logical_conjunction logical_comparison primary argument function_call case_statement decision iterator
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
                            printf("    ");
                        }
                        printf("Constructing new table for a new scope: %d\n", symbolTable->size);
                        SymbolTable_push(symbolTable);
                        if (lastSymbol->kind == KIND_FUNC && currFunc) {
                            yyerror("Invalid statement: cannot declare a function inside a function.");
                        }
                        if (lastSymbol->kind == KIND_FUNC && !currFunc) {
                            currFunc = lastSymbol;
                        }
                        if (lastSymbol->kind == KIND_FUNC && lastSymbol->numParams > 0) {
                            for (int i = 0; i < numParams; i++) {
                                Symbol* param = lastSymbol->params[i];
                                if (ScopeSymbolTable_get(symbolTable->head, param->name)) {
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
                                    printf("    ");
                                }
                                printf("Declared a function parameter \"%s\" of type \"%s\"\n", param->name, type_str);
                                Symbol* symbol = Symbol_construct(param->name, param->kind, param->isInit, param->value, NULL, 0);
                                SymbolTable_insert(symbolTable, symbol);
                            }
                        }
                    }
        statements
        SCOPE_END   {
                        if (funcDepth == 0) {
                            currFunc = NULL;
                        }
                        for (int i = 0; i < symbolTable->size - 1; i++) {
                            printf("    ");
                        }
                        printf("Destroying table for scope: %d\n", symbolTable->size - 1);
                        SymbolTable_pop(symbolTable);
                        if (currFunc) {
                            funcDepth = funcDepth - 1;
                        }
                    }
      ;

declaration : TYPE IDENTIFIER                           {
                                                            if (ScopeSymbolTable_get(symbolTable->head, $2)) {
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
                                                                yyerror("Invalid declaration: cannot create a variable of unknown type.");
                                                            }
                                                            for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                printf("    ");
                                                            }
                                                            printf("Declared a variable \"%s\" of type \"%s\"\n", $2, $1);
                                                            Symbol* symbol = Symbol_construct($2, KIND_VAR, 0, value, NULL, 0);
                                                            SymbolTable_insert(symbolTable, symbol);
                                                            lastSymbol = symbol;
                                                        }
            | TYPE IDENTIFIER ASSIGN expression         {
                                                            if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                yyerror("Invalid declaration: cannot redeclare symbol.");
                                                            }
                                                            Value value;
                                                            if (strcmp($1, "bool") == 0) {
                                                                value.type = TYPE_BOOL;
                                                                if ($4->type != TYPE_BOOL) {
                                                                    yyerror("Invalid assignment: cannot assign non-boolean expression to \"bool\" variable.");
                                                                }
                                                                value.data.i = $4->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a variable \"%s\" of type \"%s\" and value: %s\n", $2, $1, value.data.i == 1 ? "true" : "false");
                                                            }
                                                            else if (strcmp($1, "int") == 0) {
                                                                value.type = TYPE_INT;
                                                                if ($4->type != TYPE_INT && $4->type != TYPE_FLOAT) {
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"int\" variable.");
                                                                }
                                                                value.data.i = $4->type == TYPE_INT ? $4->data.i : (int) $4->data.f;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a variable \"%s\" of type \"%s\" and value: %d\n", $2, $1, value.data.i);
                                                            }
                                                            else if (strcmp($1, "float") == 0) {
                                                                value.type = TYPE_FLOAT;
                                                                if ($4->type != TYPE_INT && $4->type != TYPE_FLOAT) {
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"float\" variable.");
                                                                }
                                                                value.data.f = $4->type == TYPE_FLOAT ? $4->data.f : (float) $4->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a variable \"%s\" of type \"%s\" and value: %f\n", $2, $1, value.data.f);
                                                            }
                                                            else if (strcmp($1, "char") == 0) {
                                                                value.type = TYPE_CHAR;
                                                                if ($4->type != TYPE_CHAR) {
                                                                    yyerror("Invalid assignment: cannot assign non-character expression to \"char\" variable.");
                                                                }
                                                                value.data.c = $4->data.c;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a variable \"%s\" of type \"%s\" and value: %c\n", $2, $1, value.data.c);
                                                            }
                                                            else if (strcmp($1, "string") == 0) {
                                                                value.type = TYPE_STRING;
                                                                if ($4->type != TYPE_STRING) {
                                                                    yyerror("Invalid assignment: cannot assign non-string expression to \"string\" variable.");
                                                                }
                                                                value.data.s = $4->data.s;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a variable \"%s\" of type \"%s\" and value: %s\n", $2, $1, value.data.s);
                                                            }
                                                            else {
                                                                yyerror("Invalid declaration: cannot create a variable of unknown type.");
                                                            }
                                                            Symbol* symbol = Symbol_construct($2, KIND_VAR, 1, value, NULL, 0);
                                                            SymbolTable_insert(symbolTable, symbol);
                                                            lastSymbol = symbol;
                                                        }
            | CONST TYPE IDENTIFIER ASSIGN expression   {
                                                            if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                yyerror("Invalid declaration: cannot redeclare symbol.");
                                                            }
                                                            Value value;
                                                            if (strcmp($2, "bool") == 0) {
                                                                value.type = TYPE_BOOL;
                                                                if ($5->type != TYPE_BOOL) {
                                                                    yyerror("Invalid assignment: cannot assign non-boolean expression to \"bool\" constant.");
                                                                }
                                                                value.data.i = $5->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a constant \"%s\" of type \"%s\" and value: %s\n", $3, $2, value.data.i == 1 ? "true" : "false");
                                                            }
                                                            else if (strcmp($2, "int") == 0) {
                                                                value.type = TYPE_INT;
                                                                if ($5->type != TYPE_INT && $5->type != TYPE_FLOAT) {
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"int\" constant.");
                                                                }
                                                                value.data.i = $5->type == TYPE_INT ? $5->data.i : (int) $5->data.f;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a constant \"%s\" of type \"%s\" and value: %d\n", $3, $2, value.data.i);
                                                            }
                                                            else if (strcmp($2, "float") == 0) {
                                                                value.type = TYPE_FLOAT;
                                                                if ($5->type != TYPE_INT && $5->type != TYPE_FLOAT) {
                                                                    yyerror("Invalid assignment: cannot assign non-numeric expression to \"float\" constant.");
                                                                }
                                                                value.data.f = $5->type == TYPE_FLOAT ? $5->data.f : (float) $5->data.i;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a constant \"%s\" of type \"%s\" and value: %f\n", $3, $2, value.data.f);
                                                            }
                                                            else if (strcmp($2, "char") == 0) {
                                                                value.type = TYPE_CHAR;
                                                                if ($5->type != TYPE_CHAR) {
                                                                    yyerror("Invalid assignment: cannot assign non-character expression to \"char\" constant.");
                                                                }
                                                                value.data.c = $5->data.c;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a constant \"%s\" of type \"%s\" and value: %c\n", $3, $2, value.data.c);
                                                            }
                                                            else if (strcmp($2, "string") == 0) {
                                                                value.type = TYPE_STRING;
                                                                if ($5->type != TYPE_STRING) {
                                                                    yyerror("Invalid assignment: cannot assign non-string expression to \"string\" constant.");
                                                                }
                                                                value.data.s = $5->data.s;
                                                                for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                    printf("    ");
                                                                }
                                                                printf("Declared a constant \"%s\" of type \"%s\" and value: %s\n", $3, $2, value.data.s);
                                                            }
                                                            else {
                                                                yyerror("Invalid declaration: cannot create a constant of unknown type.");
                                                            }
                                                            Symbol* symbol = Symbol_construct($2, KIND_CONST, 1, value, NULL, 0);
                                                            SymbolTable_insert(symbolTable, symbol);
                                                            lastSymbol = symbol;
                                                        }
            ;

assignment : IDENTIFIER ASSIGN expression   {
                                                Symbol* var = SymbolTable_get(symbolTable, $1);
                                                if (!var) {
                                                    yyerror("Invalid expression: cannot find symbol.");
                                                }
                                                if (var->kind == KIND_FUNC || var->kind == KIND_CONST) {
                                                    yyerror("Invalid assignment: cannot assign to a constant or a function.");
                                                }
                                                if ($3->type != var->value.type) {
                                                    yyerror("Invalid assignment: type of variable does not match type of expression.");
                                                }
                                                switch (var->value.type) {
                                                    case TYPE_BOOL:
                                                        var->value.data.i = $3->data.i;
                                                        break;
                                                    case TYPE_INT:
                                                        var->value.data.i = $3->data.i;
                                                        break;
                                                    case TYPE_FLOAT:
                                                        var->value.data.f = $3->data.f;
                                                        break;
                                                    case TYPE_CHAR:
                                                        var->value.data.c = $3->data.c;
                                                        break;
                                                    case TYPE_STRING:
                                                        var->value.data.s = $3->data.s;
                                                        break;
                                                }
                                            }
           ;

decision : expression   {
                            if ($1->type != TYPE_BOOL) {
                                yyerror("Invalid statement: cannot use a non-boolean expression as a decision expression.");
                            }
                            $$ = $1;
                        }

iterator : expression   {
                            if ($1->type != TYPE_INT) {
                                yyerror("Invalid statement: cannot use a non-integer expression as an iterator expression.");
                            }
                            $$ = $1;
                        }

if_statement : IF OPENING_PARENTHESIS decision CLOSING_PARENTHESIS block
             | IF OPENING_PARENTHESIS decision CLOSING_PARENTHESIS block ELSE block
             ;

switch_statement : SWITCH OPENING_PARENTHESIS expression CLOSING_PARENTHESIS SCOPE_START case_statements SCOPE_END              {
                                                                                                                                    for (int i = 0; i < numCases; i++) {
                                                                                                                                        if ($3->type != ($6)[i]->type) {
                                                                                                                                            yyerror("Invalid case statement: type of expression inside the switch statement does not match the types of expressions inside the case statements.");
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                 | SWITCH OPENING_PARENTHESIS expression CLOSING_PARENTHESIS SCOPE_START case_statements default_case SCOPE_END {
                                                                                                                                    for (int i = 0; i < numCases; i++) {
                                                                                                                                        if ($3->type != ($6)[i]->type) {
                                                                                                                                            yyerror("Invalid case statement: type of expression inside the switch statement does not match the types of expressions inside the case statements.");
                                                                                                                                        }
                                                                                                                                    }
                                                                                                                                }
                 ;

case_statements : case_statements case_statement    {
                                                        numCases = numCases + 1;
                                                        $$ = malloc(numCases * sizeof(Value*));
                                                        for (int i = 0; i < numCases - 1; i++) {
                                                            ($$)[i] = ($1)[i];
                                                        }
                                                        ($$)[numCases - 1] = $2;
                                                    }
                | case_statement                    {
                                                        numCases = 1;
                                                        $$ = malloc(sizeof(Value*));
                                                        ($$)[0] = $1;
                                                    }
                ;

case_statement : CASE OPENING_PARENTHESIS expression CLOSING_PARENTHESIS block  {
                                                                                    $$ = $3;
                                                                                }
               ;

default_case : DEFAULT block
             ;

for_loop : FOR IDENTIFIER FROM OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS TO OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS block                                                       {
                                                                                                                                                                                                    Symbol* var = SymbolTable_get(symbolTable, $2);
                                                                                                                                                                                                    if (!var) {
                                                                                                                                                                                                        yyerror("Invalid expression: cannot find symbol.");
                                                                                                                                                                                                    }
                                                                                                                                                                                                    if (var->kind == KIND_FUNC || var->kind == KIND_CONST) {
                                                                                                                                                                                                        yyerror("Invalid statemen: cannot use a constant or a function as a for loop iterator.");
                                                                                                                                                                                                    }
                                                                                                                                                                                                    if (var->value.type != TYPE_INT) {
                                                                                                                                                                                                        yyerror("Invalid statement: cannot use a non-integer variable as a for loop iterator.");
                                                                                                                                                                                                    }
                                                                                                                                                                                                }
         | FOR IDENTIFIER FROM OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS TO OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS STEP OPENING_PARENTHESIS iterator CLOSING_PARENTHESIS block {
                                                                                                                                                                                                    Symbol* var = SymbolTable_get(symbolTable, $2);
                                                                                                                                                                                                    if (!var) {
                                                                                                                                                                                                        yyerror("Invalid expression: cannot find symbol.");
                                                                                                                                                                                                    }
                                                                                                                                                                                                    if (var->kind == KIND_FUNC || var->kind == KIND_CONST) {
                                                                                                                                                                                                        yyerror("Invalid statemen: cannot use a constant or a function as a for loop iterator.");
                                                                                                                                                                                                    }
                                                                                                                                                                                                    if (var->value.type != TYPE_INT) {
                                                                                                                                                                                                        yyerror("Invalid statement: cannot use a non-integer variable as a for loop iterator.");
                                                                                                                                                                                                    }
                                                                                                                                                                                                }
         ;

while_loop : WHILE OPENING_PARENTHESIS decision CLOSING_PARENTHESIS block
           ;

repeat_loop : REPEAT block UNTIL OPENING_PARENTHESIS decision CLOSING_PARENTHESIS
            ;

function_declaration : VOID IDENTIFIER OPENING_PARENTHESIS parameter_list CLOSING_PARENTHESIS   {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    value.type = TYPE_VOID;
                                                                                                    value.data.i = 0;
                                                                                                    for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                        printf("    ");
                                                                                                    }
                                                                                                    printf("Declared a function \"%s\" of type \"void\" with %d parameters.\n", $2, numParams);
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, value, $4, numParams);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     | TYPE IDENTIFIER OPENING_PARENTHESIS parameter_list CLOSING_PARENTHESIS   {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    if (strcmp($1, "bool") == 0) {
                                                                                                        value.type = TYPE_BOOL;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "int") == 0) {
                                                                                                        value.type = TYPE_INT;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "float") == 0) {
                                                                                                        value.type = TYPE_FLOAT;
                                                                                                        value.data.f = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "char") == 0) {
                                                                                                        value.type = TYPE_CHAR;
                                                                                                        value.data.c = '0';
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else if (strcmp($1, "string") == 0) {
                                                                                                        value.type = TYPE_STRING;
                                                                                                        value.data.s = "";
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\" with %d parameters.\n", $2, $1, numParams);
                                                                                                    }
                                                                                                    else {
                                                                                                        yyerror("Invalid declaration: cannot create a function of unknown type.");
                                                                                                    }
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, value, $4, numParams);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     | VOID IDENTIFIER OPENING_PARENTHESIS CLOSING_PARENTHESIS                  {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    value.type = TYPE_VOID;
                                                                                                    value.data.i = 0;
                                                                                                    for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                        printf("    ");
                                                                                                    }
                                                                                                    printf("Declared a function \"%s\" of type \"void\"\n", $2);
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, value, NULL, 0);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
                                                                                                    lastSymbol = symbol;
                                                                                                }
                       block
                     | TYPE IDENTIFIER OPENING_PARENTHESIS CLOSING_PARENTHESIS                  {
                                                                                                    if (ScopeSymbolTable_get(symbolTable->head, $2)) {
                                                                                                        yyerror("Invalid declaration: cannot redeclare symbol.");
                                                                                                    }
                                                                                                    Value value;
                                                                                                    if (strcmp($1, "bool") == 0) {
                                                                                                        value.type = TYPE_BOOL;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "int") == 0) {
                                                                                                        value.type = TYPE_INT;
                                                                                                        value.data.i = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "float") == 0) {
                                                                                                        value.type = TYPE_FLOAT;
                                                                                                        value.data.f = 0;
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "char") == 0) {
                                                                                                        value.type = TYPE_CHAR;
                                                                                                        value.data.c = '0';
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else if (strcmp($1, "string") == 0) {
                                                                                                        value.type = TYPE_STRING;
                                                                                                        value.data.s = "";
                                                                                                        for (int i = 0; i < symbolTable->size - 1; i++) {
                                                                                                            printf("    ");
                                                                                                        }
                                                                                                        printf("Declared a function \"%s\" of type \"%s\"\n", $2, $1);
                                                                                                    }
                                                                                                    else {
                                                                                                        yyerror("Invalid declaration: cannot create a function of unknown type.");
                                                                                                    }
                                                                                                    Symbol* symbol = Symbol_construct($2, KIND_FUNC, 1, value, NULL, 0);
                                                                                                    SymbolTable_insert(symbolTable, symbol);
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
                                    yyerror("Invalid declaration: cannot create a parameter of unknown type.");
                                }
                                $$ = Symbol_construct($2, KIND_VAR, 1, value, NULL, 0);
                            }
          ;

return_statement : RETURN expression    {
                                            if (!currFunc) {
                                                yyerror("Invalid statement: cannot use a return statement outside a function.");
                                            }
                                            if (currFunc->value.type == TYPE_VOID) {
                                                yyerror("Invalid statement: cannot use a return statement in a \"void\" function.");
                                            }
                                            if ($2->type != currFunc->value.type) {
                                                yyerror("Invalid statement: returned expression does not match function return type.");
                                            }
                                        }
                 ;

function_call : IDENTIFIER OPENING_PARENTHESIS argument_list CLOSING_PARENTHESIS    {
                                                                                        Symbol* func = SymbolTable_get(symbolTable, $1);
                                                                                        if (!func) {
                                                                                            yyerror("Invalid expression: cannot find symbol.");
                                                                                        }
                                                                                        if (func->kind == KIND_VAR || func->kind == KIND_CONST) {
                                                                                            yyerror("Invalid expression: cannot use a variable or constant as a function.");
                                                                                        }
                                                                                        if (numArgs != func->numParams) {
                                                                                            yyerror("Invalid expression: number of arguments is not equal to number of parameters.");
                                                                                        }
                                                                                        for (int i = 0; i < numArgs; i++) {
                                                                                            Symbol* param = func->params[i];
                                                                                            if (($3)[i]->type != param->value.type) {
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
                                                                                    }
              | IDENTIFIER OPENING_PARENTHESIS CLOSING_PARENTHESIS                  {
                                                                                        Symbol* func = SymbolTable_get(symbolTable, $1);
                                                                                        if (!func) {
                                                                                            yyerror("Invalid expression: cannot find symbol.");
                                                                                        }
                                                                                        if (func->kind == KIND_VAR || func->kind == KIND_CONST) {
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
                                                                        yyerror("Invalid expression: cannot perform a disjunction operation between non-boolean expressions.");
                                                                    }
                                                                    $$ = malloc(sizeof(Value));
                                                                    $$->type = TYPE_BOOL;
                                                                    $$->data.i = $1->data.i || $3->data.i;
                                                                }
                   | logical_conjunction                        {
                                                                    $$ = $1;
                                                                }
                   ;

logical_conjunction : logical_conjunction AND logical_comparison    {
                                                                        if ($1->type != TYPE_BOOL || $3->type != TYPE_BOOL) {
                                                                            yyerror("Invalid expression: cannot perform a conjunction operation between non-boolean expressions.");
                                                                        }
                                                                        $$ = malloc(sizeof(Value));
                                                                        $$->type = TYPE_BOOL;
                                                                        $$->data.i = $1->data.i && $3->data.i;
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
                                                                                yyerror("Invalid expression: cannot compare between different-typed expressions.");
                                                                            }
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
                                                                                yyerror("Invalid expression: cannot compare between different-typed expressions.");
                                                                            }
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
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
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
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
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
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
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
                                                                                yyerror("Invalid expression: cannot compare between boolean expressions, string expressions, or different-typed expressions.");
                                                                            }
                                                                        }
                   | mathematical_expression                            {
                                                                            $$ = $1;
                                                                        }
                   ;

mathematical_expression : mathematical_expression PLUS mathematical_term    {
                                                                                if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
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
                                                                            }
                        | mathematical_expression MINUS mathematical_term   {
                                                                                if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
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
                                                                            }
                        | mathematical_term                                 {
                                                                                $$ = $1;
                                                                            }
                        ;

mathematical_term : mathematical_term MULT mathematical_exponent    {
                                                                        if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
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
                                                                    }
                  | mathematical_term DIV mathematical_exponent     {
                                                                        if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
                                                                            yyerror("Invalid expression: cannot perform a division operation between non-numeric expressions.");
                                                                        }
                                                                        if (($3->type == TYPE_INT && $3->data.i == 0) || ($3->type == TYPE_FLOAT && $3->data.f == 0)) {
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
                                                                    }
                  | mathematical_term MOD mathematical_exponent     {
                                                                        if ($1->type != TYPE_INT || $3->type != TYPE_INT) {
                                                                            yyerror("Invalid expression: cannot perform a remainder operation between non-integer expressions.");
                                                                        }
                                                                        if ($3->data.i == 0) {
                                                                            yyerror("Invalid expression: cannot divide by zero.");
                                                                        }
                                                                        $$ = malloc(sizeof(Value));
                                                                        $$->type = TYPE_INT;
                                                                        $$->data.i = $1->data.i % $3->data.i;
                                                                    }
                  | mathematical_exponent                           {
                                                                        $$ = $1;
                                                                    }
                  ;

mathematical_exponent : primary POW mathematical_exponent   {
                                                                if (($1->type != TYPE_INT && $1->type != TYPE_FLOAT) || ($3->type != TYPE_INT && $3->type != TYPE_FLOAT)) {
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
                                                                        }
        | NOT primary                                                   {
                                                                            if ($2->type != TYPE_BOOL) {
                                                                                yyerror("Invalid expression: cannot perform an inversion operation on a non-boolean expression.");
                                                                            }
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_BOOL;
                                                                            $$->data.i = !($2->data.i);
                                                                        }
        | INTEGER                                                       {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_INT;
                                                                            $$->data.i = $1;
                                                                        }
        | FLOAT                                                         {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_FLOAT;
                                                                            $$->data.f = $1;
                                                                        }
        | BOOL                                                          {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_BOOL;
                                                                            $$->data.i = $1;
                                                                        }
        | CHAR                                                          {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_CHAR;
                                                                            $$->data.c = $1;
                                                                        }
        | STRING                                                        {
                                                                            $$ = malloc(sizeof(Value));
                                                                            $$->type = TYPE_STRING;
                                                                            $$->data.s = $1;
                                                                        }
        | IDENTIFIER                                                    {
                                                                            $$ = malloc(sizeof(Value));
                                                                            Symbol* symbol = SymbolTable_get(symbolTable, $1);
                                                                            if (!symbol) {
                                                                                yyerror("Invalid expression: cannot find symbol.");
                                                                            }
                                                                            if (symbol->kind != KIND_VAR && symbol->kind != KIND_CONST) {
                                                                                yyerror("Invalid expression: cannot call function without argument list.");
                                                                            }
                                                                            if (!(symbol->isInit)) {
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
                                                                        }
        | function_call                                                 {
                                                                            if ($1->type == TYPE_VOID) {
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
    fprintf(stderr, "\nError: %s\n", s);
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

    symbolTable = SymbolTable_construct();
    numParams = 0;
    lastSymbol = NULL;
    numArgs = 0;
    numCases = 0;
    currFunc = NULL;
    funcDepth = 0;

    yyparse();
    fclose(yyin);
    return 0;
}