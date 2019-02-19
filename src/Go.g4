grammar Go;

@lexer::members {
    int lastTokenType = 0;
    public void emit(Token token) {
    	super.emit(token);
    	lastTokenType = token.getType();
    }
}



srcFile: ('package main' eos) (statement)* EOF ;

statement	: 	imports eos
			|	variableDec eos
			| 	functionDecl eos
 			;

imports		: 	('import' PACKAGE)  
			| 	('import' LPAREN (PACKAGE (eos PACKAGE?)*)? RPAREN)	
			;
			
variableDec	:	 VAR ID (LSQARE expression? RSQARE)? (',' ID (LSQARE expression? RSQARE)?)* type
			;

variableInit:	VAR ID (',' ID)* type (EQUAL expression (',' expression)*)?
			|	( (ID (',' ID)* ':=') | ( ('*')* ID (',' ID)* EQUAL) ) expression (',' expression)* //VAR_ASSIGN/INIT_2
			|	VAR ID (',' ID)* EQUAL expression (',' expression)*
			|	ID (',' ID)* ':=' expression (',' expression)*
			|	VAR ID type? EQUAL (expression)
			|	arrayAccess EQUAL (expression)
			|	CONST ID type EQUAL (expression)
			|	CONST ID ':=' (expression)
			|	CONST ID EQUAL (expression)
			;

arrayAccess	:	ID LSQARE expression RSQARE
			|	ID LSQARE expression? ':' expression? RSQARE 
			;	

functionDecl : 	'func' ID LPAREN funcArgs? RPAREN (LPAREN funcOut+ RPAREN)?  block
			;

funcArgs	: 	ID type (',' ID type)*	;

funcOut		:	ID? type (',' ID? type)*	;

functionCall: 	'go'? ID LPAREN (expression (',' expression)*)? RPAREN 					# Call										
			|	'go'? 'func' LPAREN funcArgs? RPAREN (LPAREN funcOut+ RPAREN)? block (LPAREN (value (',' value)*)? RPAREN)?  # Call
			;

block		: 	LBRACE (insideBlockStat eos)* RBRACE;

insideBlockStat	:	'return' expression?
				|	variableDec
				|	variableInit
				|	forStatement 
				| 	ifStatement 
				| 	functionCall
				| 	ID '++'
				| 	ID '--'
				|	'<-' ID
				|   ID '<-' expression
				| 	'fmt.Println' LPAREN expression (',' expression)* RPAREN
				;

typeConversion: ID '.' LPAREN type RPAREN ; // type assertion 

ifStatement :  'if' expression boolOp expression block ('else if' expression boolOp expression block)* ('else' block)? ; 						// else if not working

forStatement:  'for' expression? block
			|  'for' (ID (':='|EQUAL) expression)? ';' expression boolOp expression ';' expression? block
			;

switchStat	:  'switch' (ID|expression boolOp expression|(variableInit SEMICOLON ID))? LBRACE switchCase block RBRACE;

switchCase	:	'case' expression SEMICOLON
			|	'default' SEMICOLON
			;

expression	:	'len' LPAREN expression RPAREN
			| 	functionCall											
			| 	'make' LPAREN 'chan' (',' expression)? type RPAREN						
			|	'make' LPAREN LSQARE RSQARE type ',' expression (',' expression)? RPAREN
			|	LSQARE expression? RSQARE type  LBRACE expression ':' expression (',' expression ':' expression expression)* RBRACE
			|	LSQARE expression? RSQARE type  LBRACE expression (',' expression)* RBRACE
			|	arrayAccess
		 	|	expression '++'
		 	|	expression '--'
			|	typeConversion	
			|	'~' expression
			|  	'*' expression
			| 	'&' expression	
			|  	'<-' expression
			|	expression ('*'|'/'|'%') expression
			|	expression ('+'|'-') expression
			|  	<assoc=right> expression '&'expression
			|	<assoc=right> expression '^' expression
			|	<assoc=right> expression '&^' expression
			|   <assoc=right> expression '|' expression
			|   expression '<<' expression
			|   expression '>>' expression
		 	|	expression '+=' expression						
		 	|	expression '-=' expression						
		 	|	expression '*=' expression						
		 	|	expression '/=' expression						
		 	|	expression '%=' expression						
		 	|	expression '<<=' expression						
		 	|	expression '>>=' expression						
		 	|	expression '&=' expression						
		 	|	expression '^=' expression						
		 	|	expression '|=' expression				
			| 	ID
			|	value
			|	LPAREN expression RPAREN
			|	'!' expression 
			;

boolOp:	'<' |'>'|'<='|'>='|'=='|'!=' |'||'|'&&';

type	: 	'int' | 'uint' | 'bool' | 'string' | 'float32' | 'float64' | 'rune' | 'byte' | 'complex64' | 'complex128'|'*' type | 'chan' type | LSQARE RSQARE type;

value :	INT ;

eos 	: 	SEMICOLON
		|   NEWLINE
		| 	EOF
		;



// Lexer


VAR : 'var' ;

CONST : 'const' ;

PACKAGE	  : '"' [a-z/]+ '"';

ID:	[a-zA-Z][_a-zA-Z0-9]* ; 

INT: [0-9]+ ;

LPAREN    : '(' ;

RPAREN    : ')' ;

LBRACE    : '{' ;

RBRACE    : '}' ;

LSQARE    : '[' ;

RSQARE    : ']' ;

SEMICOLON : ';' ;

EQUAL : '=' ;

WS  :   (' ' | '\t')+ -> skip
    ;

NEWLINE:
    '\r'? '\n' {if (_input.LA(1) == '\n' || lastTokenType == SEMICOLON || lastTokenType == NEWLINE || lastTokenType == LBRACE ||  lastTokenType == LPAREN || _input.LA(1) == RBRACE || _input.LA(1) == RPAREN) skip();}
    ;

COMMENT
    :   '//' ~[\r\n]* -> skip
    ;