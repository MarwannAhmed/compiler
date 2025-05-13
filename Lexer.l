/* Definitions */
%{
    #include "globals.h"

    #include "Parser.tab.h"
%}

/* Regex Rules */
%%
"//".*                                              { /* Ignore single-line comments */ }
"/*"([^*]|(\*)[^/])*"*/"                            { /* Ignore multi-line comments */ }
("false"|"true")                                    {yylval.i = (yytext[0] == 't'); return BOOL;}
[0-9]+                                              {yylval.i = atoi(yytext); return INTEGER;}
[0-9]+\.[0-9]+                                      {yylval.f = atof(yytext); return FLOAT;}
\'([^\']|\\.)\'                                     {
                                                        char result;
                                                        if (yytext[1] == '\\') {
                                                            switch (yytext[2]) {
                                                                case 'n': result = '\n'; break;
                                                                case 't': result = '\t'; break;
                                                                case 'r': result = '\r'; break;
                                                                case '0': result = '\0'; break;
                                                                case '\\': result = '\\'; break;
                                                                case '\'': result = '\''; break;
                                                                case '\"': result = '\"'; break;
                                                                default:
                                                                    fprintf(stderr, "Unknown escape sequence: \\%c\n", yytext[2]);
                                                                    exit(1);
                                                            }
                                                        }
                                                        else {
                                                            result = yytext[1];
                                                        }
                                                        yylval.c = result;
                                                        return CHAR;
                                                    }
\"([^\"]|\\.)*\"                                    {
                                                        char *content = strdup(yytext + 1);
                                                        content[strlen(content) - 1] = '\0';
                                                        char *decoded = (char *)malloc(strlen(content) + 1);
                                                        int decoded_index = 0;
                                                        for (int i = 0; i < strlen(content); i++) {
                                                            if (content[i] == '\\' && i + 1 < strlen(content)) {
                                                                switch (content[i + 1]) {
                                                                    case 'n': decoded[decoded_index++] = '\n'; i++; break;
                                                                    case 't': decoded[decoded_index++] = '\t'; i++; break;
                                                                    case 'r': decoded[decoded_index++] = '\r'; i++; break;
                                                                    case '0': decoded[decoded_index++] = '\0'; i++; break;
                                                                    case '\\': decoded[decoded_index++] = '\\'; i++; break;
                                                                    case '\"': decoded[decoded_index++] = '\"'; i++; break;
                                                                    case '\'': decoded[decoded_index++] = '\''; i++; break;
                                                                    default:
                                                                        fprintf(stderr, "Unknown escape sequence: \\%c\n", content[i + 1]);
                                                                        exit(1);
                                                                }
                                                            }
                                                            else {
                                                                decoded[decoded_index++] = content[i];
                                                            }
                                                        }
                                                        decoded[decoded_index] = '\0';
                                                        yylval.s = decoded;
                                                        return STRING;
                                                    }
("bool"|"int"|"float"|"char"|"string")              {yylval.s = strdup(yytext); return TYPE;}
"void"                                              {return VOID;}
"const"                                             {return CONST;}
"if"                                                {return IF;}
"else"                                              {return ELSE;}
"switch"                                            {return SWITCH;}
"case"                                              {return CASE;}
"default"                                           {return DEFAULT;}
"for"                                               {return FOR;}
"from"                                              {return FROM;}
"to"                                                {return TO;}
"step"                                              {return STEP;}
"while"                                             {return WHILE;}
"repeat"                                            {return REPEAT;}
"until"                                             {return UNTIL;}
"return"                                            {return RETURN;}
"print"                                             {return PRINT;}
";"                                                 {return SEMICOLON;}
"="                                                 {return ASSIGN;}
"+"                                                 {return PLUS;}
"-"                                                 {return MINUS;}
"*"                                                 {return MULT;}
"/"                                                 {return DIV;}
"%"                                                 {return MOD;}
"^"                                                 {return POW;}
"("                                                 {return OPENING_PARENTHESIS;}
")"                                                 {return CLOSING_PARENTHESIS;}
"{"                                                 {return SCOPE_START;}
"}"                                                 {return SCOPE_END;}
"&"                                                 {return AND;}
"|"                                                 {return OR;}
"!"                                                 {return NOT;}
"<"                                                 {return LT;}
"<="                                                {return LE;}
">"                                                 {return GT;}
">="                                                {return GE;}
"=="                                                {return EQ;}
"!="                                                {return NE;}
","                                                 {return COMMA;}
[a-zA-Z_][a-zA-Z0-9_]*                              {yylval.s = strdup(yytext); return IDENTIFIER;}
[ \t\n]+                                            { /* Ignore whitespace */ }
%%

/* Subroutines */
int yywrap(void) {
    return 1;
}