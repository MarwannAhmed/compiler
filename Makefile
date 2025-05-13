.PHONY: all clean build bison flex comp

all: clean build run

clean:
	rm -rf Compiler.exe Parser.tab.c Parser.tab.h lex.yy.c Parser.output .vscode

build: bison flex comp

run:
	./Compiler.exe src.txt

bison:
	bison.exe -d -v Parser.y

flex:
	flex.exe Lexer.l

comp:
	gcc.exe SymbolTableDefs/Symbol.c SymbolTableDefs/SymbolList.c SymbolTableDefs/ScopeSymbolTable.c SymbolTableDefs/SymbolTable.c globals.c utils.c Parser.tab.c lex.yy.c -o Compiler.exe