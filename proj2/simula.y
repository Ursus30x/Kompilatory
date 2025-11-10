%{
#include <stdio.h> /* printf() */
#include <string.h> /* strcpy() */
#include "common.h" /* MAX_STR_LEN */
int yylex(void);
void yyerror(const char *txt);
 
void found( const char *nonterminal, const char *value );
%}

%union 
{
        char s[ MAX_STR_LEN + 1 ]; /* text field for idents etc. */
        int i; /* integer field */
        double d; /* floating point field */
}

%token<i> KW_ACTIVATE KW_AFTER KW_AND KW_ARRAY KW_AT KW_BEFORE KW_BEGIN
%token<i> KW_BOOLEAN KW_CHARACTER KW_CLASS KW_COMMENT KW_DELAY KW_DO
%token<i> KW_ELSE KW_END KW_EQ KW_EQV KW_EXTERNAL KW_FALSE KW_FOR KW_GE
%token<i> KW_GO KW_GOTO KW_GT KW_HIDDEN KW_IF KW_IMP KW_IN KW_INNER
%token<i> KW_INSPECT KW_INTEGER KW_IS KW_LABEL KW_LONG KW_LT KW_NAME KW_NE
%token<i> KW_NEW KW_NONE KW_NOT KW_NOTEXT KW_OR KW_OTHERWISE KW_PRIOR
%token<i> KW_PROCEDURE KW_PROTECTED KW_QUA KW_REACTIVATE KW_REAL KW_REF
%token<i> KW_SHORT KW_STEP KW_SWITCH KW_TEXT KW_THEN KW_THIS KW_TO KW_TRUE
%token<i> KW_UNTIL KW_VALUE KW_VIRTUAL KW_WHEN KW_WHILE
%token<i> INTEGER_CONST
%token<s> TEXT_CONST CHARACTER_CONST IDENT
%token<i> ASSIGN REF_ASSIGN INT_DIV EXPO REF_EQ REF_NE POWER
%token<d> REAL_CONST

 /* Precedence of operators */
%left '+' '-'
%left '*' '/' INT_DIV
%left EXPO
%nonassoc '<' KW_LE '=' KW_GE '>' KW_NE KW_IS KW_IN
%right KW_NOT

%type<s> MAIN_PART PROCEDURE_HEADING IDENTIFIER_1 PROCEDURE_STATEMENT PROCEDURE_DECLARATION OPT_IDENT
%type<s> REMOTE_PREFIX

%%

 /* Structure of a Simula program */

 /* program can be empty (semantic error),
    it may contain a syntax error,
    or it may consist of statements (STATEMENTS) */
GRAMMAR: %empty { yyerror("File is ampty"); YYERROR; }
	| error
   | STATEMENTS { found("End of program.", ""); }
   ;

/* BLOCK */
/* Block head (BLOCK_HEAD) followed by compound tail (COMPOUND_TAIL) */
BLOCK
   : BLOCK_HEAD COMPOUND_TAIL { found("STATEMENT",""); found("BLOCK",""); }
   ;

/* BLOCK_HEAD */
/* Keyword begin followed by a sequence of:
   declarations (DECLARATION) followed by semicolon */
///!!! WARNING, CHECK IF IT DOES LIST SEQUENCE PROPERLY
BLOCK_HEAD 
   : KW_BEGIN DECLARATION ';'
   | BLOCK_HEAD DECLARATION ';'
   ;

/* DECLARATION */
/* Either: procedure declaration (PROCEDURE_DECLARATION),
   or: class declaration (CLASS_DECLARATION),
   or: simple variable declaration (SIMPLE_VARIABLE_DECLARATION),
   or: array declaration (ARRAY_DECLARATION) */
DECLARATION
   : PROCEDURE_DECLARATION { found("DECLARATION", ""); }
   | CLASS_DECLARATION { found("DECLARATION", ""); }
   | SIMPLE_VARIABLE_DECLARATION { found("DECLARATION", ""); }
   | ARRAY_DECLARATION { found("DECLARATION", ""); }
   ;

/* CLASS_DECLARATION */
/* Optional identifier (OPT_IDENT) followed by main part (MAIN_PART) */
CLASS_DECLARATION
   : OPT_IDENT MAIN_PART { found("CLASS_DECLARATION", $2); }
   ;

/* OPT_IDENT */
/* Either empty or identifier */
OPT_IDENT
   : %empty          { strcpy($$, ""); }
   | IDENT           { strcpy($$, $1); }
   ;

/* MAIN_PART */
/* Keyword class followed by identifier, formal-value-specification part
   (FVS_PART), semicolon, optional virtual part (OPT_VIRTUAL_PART),
   and class body (CLASS_BODY). */
MAIN_PART
   : KW_CLASS IDENT FVS_PART ';' OPT_VIRTUAL_PART CLASS_BODY 
   { 
      found("MAIN_PART", $2); 
      strcpy($$, $2);
   }
   ;

/* FVS_PART */
/* Either empty or a sequence of formal parameter part (FORMAL_PARAMETER_PART),
   semicolon, optional value part (OPT_VALUE_PART), and specification part
   (SPECIFICATION_PART) */
FVS_PART
   : %empty { found("empty FVS_PART",""); }
   | FORMAL_PARAMETER_PART ';' OPT_VALUE_PART SPECIFICATION_PART { found("FVS_PART",""); }
   ;

/* FORMAL_PARAMETER_PART */
/* List of identifiers (IDENTIFIER_LIST) in parentheses */
FORMAL_PARAMETER_PART
   : '(' IDENTIFIER_LIST ')' { found("FORMAL_PARAMETER_PART",""); }
   | %empty
   ;

/* IDENTIFIER_LIST */
/* Comma-separated list of identifiers */
IDENTIFIER_LIST
   : IDENT
   | IDENTIFIER_LIST ',' IDENT
   ;

/* OPT_VIRTUAL_PART */
/* Either empty or virtual part followed by semicolon */
OPT_VIRTUAL_PART
   : %empty { found("empty VIRTUAL_PART", ""); }
   | VIRTUAL_PART ';' { found("VIRTUAL_PART", ""); }
   ;

/* VIRTUAL_PART */
/* Keyword virtual followed by a colon, and a non-empty sequence
   of virtual specifications (VIRTUAL_SPEC), each followed by a semicolon */
///!!! WARNING, CHECK IF IT DOES LIST SEQUENCE PROPERLY
VIRTUAL_PART   
   : KW_VIRTUAL ':' VIRTUAL_SPEC ';' 
   | VIRTUAL_PART VIRTUAL_SPEC ';'
   ;

/* VIRTUAL_SPEC */
/* Either a specifier (SPECIFIER) followed by a list of identifiers
   (IDENTIFIER_LIST),
   or keyword procedure, followed by identifier and procedure specification
   (PROCEDURE_SPECIFICATION)
*/
VIRTUAL_SPEC
   : SPECIFIER IDENTIFIER_LIST
   | KW_PROCEDURE IDENT  PROCEDURE_SPECIFICATION
   ;

/* PROCEDURE_SPECIFICATION */
/* Keyword is, followed by procedure declaration (PROCEDURE_DECLARATION) */
PROCEDURE_SPECIFICATION
   : KW_IS PROCEDURE_DECLARATION
   ;

/* SPECIFICATION_PART */
/* A non-empty sequence of pairs: specifier (SPECIFIER) and list of identifiers
   (IDENTIFIER_LIST) */
SPECIFICATION_PART
    : SPECIFIER IDENTIFIER_LIST { found("SPECIFICATION_PART",""); }
    | SPECIFICATION_PART SPECIFIER IDENTIFIER_LIST { found("SPECIFICATION_PART",""); }
    | %empty
    ;

/* SPECIFIER */
/* Type followed by optional array or procedure parts (OPT_ARRAY_PROC) */
SPECIFIER
   : TYPE OPT_ARRAY_PROC { found("SPECIFIER",""); }
   ;

/* OPT_ARRAY_PROC */
/* Either empty, or keyword array, or keyword procedure */
OPT_ARRAY_PROC
   : %empty
   | KW_ARRAY
   | KW_PROCEDURE
   ;

/* TYPE */
/* Either value type (VALUE_TYPE) or reference type (REFERENCE_TYPE) */
TYPE
   : VALUE_TYPE
   | REFERENCE_TYPE { found("REFERENCE_TYPE",""); }
   ;

/* VALUE_TYPE */
/* Either arithmetic type (ARITHMETIC_TYPE), or keyword boolean, or keyword
   character */
VALUE_TYPE
   : ARITHMETIC_TYPE { found("VALUE_TYPE",""); }
   | KW_BOOLEAN      { found("VALUE_TYPE",""); }
   | KW_CHARACTER    { found("VALUE_TYPE",""); }
   ;

/* ARITHMETIC_TYPE */
/* Either integer type (INTEGER_TYPE) or real type (REAL_TYPE) */
ARITHMETIC_TYPE
   : INTEGER_TYPE
   | REAL_TYPE
   ;

/* INTEGER_TYPE */
/* Optional keyword short (OPT_KW_SHORT) followed by keyword integer */
INTEGER_TYPE
   : OPT_KW_SHORT KW_INTEGER
   ;

/* OPT_KW_SHORT */
/* Either empty or keyword short */
OPT_KW_SHORT
   : %empty
   | KW_SHORT
   ;

/* REAL_TYPE */
/* optional keyword long (OPT_KW_SHORT) followed by keyword real */
REAL_TYPE
   : OPT_KW_LONG KW_REAL
   ;

/* OPT_KW_LONG */
/* Either empty of keyword long */
OPT_KW_LONG
   : %empty
   | KW_LONG
   ;

/* OPT_VALUE_PART */
/* empty */
OPT_VALUE_PART
   : %empty
   | "value_part"
   ;

/* CLASS_BODY */
/* statement (STATEMENT) */
CLASS_BODY
   : STATEMENT { found("CLASS_BODY",""); }
   ;

/* COMPOUND_STATEMENT */
/* Keyword begin and compound tail (COMPOUND_TAIL) */
COMPOUND_STATEMENT
   : KW_BEGIN COMPOUND_TAIL
   ;

/* COMPOUND_TAIL */
/* Statements (STATEMENTS) followed by keyword end */
COMPOUND_TAIL
   : STATEMENTS KW_END
   ;

/* STATEMENTS */
/* Semicolon-separated list of statements (STATEMENT) */
STATEMENTS
   : STATEMENT
   | STATEMENTS ';' STATEMENT
   ;

/* STATEMENT */
/* Either unconditional statement (UNCONDITIONAL_STATEMENT)
   or for statement (FOR_STATEMENT) */
STATEMENT
   : UNCONDITIONAL_STATEMENT 
   | FOR_STATEMENT 
   ;

/* UNCONDITIONAL_STATEMENT */
/* Either: assignment statement (ASSIGNMENT_STATEMENT),
   or: possibly remote procedure statement (PROCEDURE_STATEMENT_1),
   or: possibly remote identifier (IDENTIFIER_1),
   or: object generator (OBJECT_GENERATOR),
   or: compound statement (COMPOUND_STATEMENT),
   or: block (BLOCK),
   or: a dummy statement (DUMMY_STATEMENT) */
UNCONDITIONAL_STATEMENT
   : ASSIGNMENT_STATEMENT { found("STATEMENT",""); }
   | PROCEDURE_STATEMENT_1 { found("STATEMENT",""); }
   | IDENTIFIER_1 //{ found("STATEMENT",""); }
   | OBJECT_GENERATOR { found("STATEMENT",""); }
   | COMPOUND_STATEMENT { found("STATEMENT",""); }
   | BLOCK 
   | DUMMY_STATEMENT
   ;

/* ASSIGNMENT_STATEMENT */
/* Either value assignment (VALUE_ASSIGNMENT) 
   or reference assignment (REFERENCE_ASSIGNEMENT) */
ASSIGNMENT_STATEMENT
   : VALUE_ASSIGNMENT { found("ASSIGNMENT_STATEMENT",""); }
   | REFERENCE_ASSIGNEMENT { found("ASSIGNMENT_STATEMENT",""); }
   ;

/* VALUE_ASSIGNMENT */
/* Left part of a value assignment (VALUE_LEFT_PART), followed by
   assignment operator, and the right part of a value assignment
   (VALUE_RIGHT_PART) */
VALUE_ASSIGNMENT
   : VALUE_LEFT_PART ASSIGN VALUE_RIGHT_PART
   ;

/* VALUE_LEFT_PART */
/* Either a possibly remote procedure statement (PROCEDURE_STATEMENT_1)
   or a possibly remote identifier (IDENTIFIER_1) */
VALUE_LEFT_PART
   : PROCEDURE_STATEMENT_1
   | IDENTIFIER_1
   ;

/* VALUE_RIGHT_PART */
/* Either a value expression (VALUE_EXPRESSION)
   or text expression (TEXT_EXPRESSION) or value assignment (VALUE_ASSIGNMENT)*/
VALUE_RIGHT_PART
   : VALUE_EXPRESSION 
   | TEXT_EXPRESSION
   | VALUE_ASSIGNMENT
   ;

/* DESTINATION */
/* A variable (VARIABLE) */
DESTINATION
   : VARIABLE
   ;

/* SIMPLE_TEXT_EXPRESSION */
/* Ampersand-separated list of primary text expressions (TEXT_PRIMARY) */
SIMPLE_TEXT_EXPRESSION
   : TEXT_PRIMARY
   | SIMPLE_TEXT_EXPRESSION '&' TEXT_PRIMARY
   ;

/* TEXT_PRIMARY */
/* Either: keyword notext, or text constant (TEXT_CONST),
   or variable (VARIABLE), or function designator (FUNCTION_DESIGNATOR),
   or a text expression (TEXT_EXPRESSION) in parentheses */
TEXT_PRIMARY
   : KW_NOTEXT 
   | TEXT_CONST
   | VARIABLE
   | FUNCTION_DESIGNATOR
   | '(' TEXT_EXPRESSION ')'

/* VARIABLE */
/* Either indentifier or a subscripted variable (SUBSCRIPTED_VARIABLE) */
VARIABLE
   : IDENT
   | SUBSCRIPTED_VARIABLE
   ;

/* SUBSCRIPTED_VARIABLE */
/* Identifier followed by a list of subscripts (SUBSCRIPT_LIST)
   in parentheses */
SUBSCRIPTED_VARIABLE
   : IDENT '(' SUBSCRIPT_LIST ')'
   ;

/* SUBSCRIPT_LIST */
/* Comma-separated list of subscript expressions (SUBSCRIPT_EXPRESSION) */
SUBSCRIPT_LIST
   : SUBSCRIPT_EXPRESSION
   | SUBSCRIPT_LIST ',' SUBSCRIPT_EXPRESSION
   ;

/* SUBSCRIPT_EXPRESSION */
/* Arithmetic expression (ARITHMETIC_EXPRESSION) */
SUBSCRIPT_EXPRESSION
   : ARITHMETIC_EXPRESSION
   ;

/* ARITHMETIC_EXPRESSION */
/* Either:
   unsigned number (UNSIGNED_NUMBER),
   or: function designator (FUNCTION_DESIGNATOR),
   or: sum of arithmetic expressions,
   or: difference of arithmetic expressions,
   or: multiplication of arithmetic expressions,
   or: division of arithmetic expressions,
   or: integer division of arithmetic expressions,
   or: an arithmetic expression in parentheses. */
ARITHMETIC_EXPRESSION
   : UNSIGNED_NUMBER
   | FUNCTION_DESIGNATOR
   | ARITHMETIC_EXPRESSION '+' ARITHMETIC_EXPRESSION
   | ARITHMETIC_EXPRESSION '-' ARITHMETIC_EXPRESSION
   | ARITHMETIC_EXPRESSION '*' ARITHMETIC_EXPRESSION
   | ARITHMETIC_EXPRESSION '/' ARITHMETIC_EXPRESSION
   | ARITHMETIC_EXPRESSION INT_DIV ARITHMETIC_EXPRESSION
   | '(' ARITHMETIC_EXPRESSION ')'
   ;   

/* UNSIGNED_NUMBER */
/* Either an integer constant or real constant */
UNSIGNED_NUMBER
   : INTEGER_CONST
   | REAL_CONST
   ;

/* FUNCTION_DESIGNATOR */
/* Identifier followed by actual parameter part (ACTUAL_PARAMETER_PART) */
FUNCTION_DESIGNATOR
   : IDENT ACTUAL_PARAMETER_PART
   ;

/* TEXT_EXPRESSION */
/* A simple text expression (SIMPLE_TEXT_EXPRESSION) */
TEXT_EXPRESSION
   : SIMPLE_TEXT_EXPRESSION
   ;

/* VALUE_EXPRESSION */
/* An arithmetic expression (ARITHMETIC_EXPRESSION) */
VALUE_EXPRESSION
   : ARITHMETIC_EXPRESSION
   ;

/* REFERENCE_ASSIGNEMENT */
/* Left part of reference assignment (REFERENCE_LEFT_PART),
   reference assignment operator,
   and right part or reference assignment (REFERENCE_RIGHT_PART) */
REFERENCE_ASSIGNEMENT
   : REFERENCE_LEFT_PART REF_ASSIGN REFERENCE_RIGHT_PART
   ;

/* REFERENCE_LEFT_PART */
/* Destination (DESTINATION) */
REFERENCE_LEFT_PART
   : DESTINATION
   ;

/*  REFERENCE_RIGHT_PART */
/* Either a reference expression (REFERENCE_EXPRESSION),
   or a reference assignment (REFERENCE_ASSIGNEMENT) */
REFERENCE_RIGHT_PART
   : REFERENCE_EXPRESSION
   | REFERENCE_ASSIGNEMENT
   ;

/* REFERENCE_EXPRESSION */
/* Either an object expression (OBJECT_EXPRESSION), or a text expression
   (TEXT_EXPRESSION) */
REFERENCE_EXPRESSION
   : OBJECT_EXPRESSION
   | TEXT_EXPRESSION
   ;

/* OBJECT_EXPRESSION */
/* A simple object expression (SIMPLE_OBJECT_EXPRESSION) */
OBJECT_EXPRESSION
   : SIMPLE_OBJECT_EXPRESSION
   ;

/* SIMPLE_OBJECT_EXPRESSION */
/* Either: keyword none,
   or: object generator (OBJECT_GENERATOR),
   or: an object expression in parentheses
 */
SIMPLE_OBJECT_EXPRESSION
   : KW_NONE
   | OBJECT_GENERATOR
   | '(' OBJECT_EXPRESSION ')'
   ;

/* REFERENCE_TYPE */
/* Either object reference type (OBJECT_REFERENCE_TYPE) or keword text */
REFERENCE_TYPE
   : OBJECT_REFERENCE_TYPE
   | KW_TEXT
   ;

/* OBJECT_REFERENCE_TYPE */
/* Keyword ref, followed by qualification (QUALIFICATION) in parentheses */
OBJECT_REFERENCE_TYPE
   : KW_REF '(' QUALIFICATION ')'

/* QUALIFICATION */
/* Identifier */
QUALIFICATION
   : IDENT
   ;

/* PROCEDURE_STATEMENT_1 */
/* Either a procedure statement, or a remote prefix followed by a dot,
   and a procedure statement*/
PROCEDURE_STATEMENT_1
   : PROCEDURE_STATEMENT
   | REMOTE_PREFIX '.' PROCEDURE_STATEMENT 
   ;

/* REMOTE_PREFIX */
/* A dot-separated list of mixed identifiers or procedure statements
   (PROCEDURE_STATEMENT) */
REMOTE_PREFIX
   : IDENT  
   { 
      found("REMOTE_PREFIX", $1); 
      strcpy($$, $1);
   }

   
   | PROCEDURE_STATEMENT 
   { 
      found("REMOTE_PREFIX", $1); 
      strcpy($$, $1);
   }
   | REMOTE_PREFIX '.' IDENT { found("REMOTE_PREFIX",$1); }
   | REMOTE_PREFIX '.' PROCEDURE_STATEMENT { found("REMOTE_PREFIX",$1); }
   ;

/* PROCEDURE_STATEMENT */
/* Identifier followed by actual parameter part (ACTUAL_PARAMETER_PART) */
PROCEDURE_STATEMENT
   : IDENT ACTUAL_PARAMETER_PART 
   { 
      found("PROCEDURE_STATEMENT",$1); 
      strcpy($$, $1);
   }
   ;

/* OPT_ACTUAL_PARAMETER_PART */
/* Either empty or actual parameter part (ACTUAL_PARAMETER_PART) */
OPT_ACTUAL_PARAMETER_PART
   : %empty
   | ACTUAL_PARAMETER_PART
   ;

/* ACTUAL_PARAMETER_PART */
/* Actual parameters (ACTUAL_PARAMETERS) in parentheses */
ACTUAL_PARAMETER_PART
   : '(' ACTUAL_PARAMETERS ')'
   ;

/* ACTUAL_PARAMETERS */
/* A comma-separated list of actual parameters (ACTUAL_PARAMETER) */
ACTUAL_PARAMETERS
   : ACTUAL_PARAMETER
   | ACTUAL_PARAMETERS ',' ACTUAL_PARAMETER
   ;

/* ACTUAL_PARAMETER */
/* Expression (EXPRESSION) */
ACTUAL_PARAMETER
   : EXPRESSION
   ;

/* EXPRESSION */
/* Either: integer constant (INTEGER_CONST), or identifier, or text constant
   (TEXT_CONST), or character constant (CHARACTER_CONST) */
EXPRESSION
   : INTEGER_CONST
   | IDENT
   | TEXT_CONST
   | CHARACTER_CONST
   ;

/* IDENTIFIER_1 */
/* Either an identifier, or a remote prefix (REMOTE_PREFIX) followed by dot,
   and by an identifier*/
IDENTIFIER_1
   : IDENT
   | REMOTE_PREFIX '.' IDENT
   ;

/* PROCEDURE_DECLARATION */
/* Optional type (OPT_TYPE), keyword procedure, procedure heading
   (PROCEDURE_HEADING), and procedure body (PROCEDURE_BODY) */
PROCEDURE_DECLARATION
   : OPT_TYPE KW_PROCEDURE PROCEDURE_HEADING PROCEDURE_BODY
     {
         found("PROCEDURE_DECLARATION", $3);
     }
   ;

/* OPT_TYPE */
/* Either empty or type (TYPE) */
OPT_TYPE
   : %empty
   | TYPE
   ;

/* PROCEDURE_HEADING */
/* Identifier followed by procedure parts (PROCEDURE_PARTS) */
PROCEDURE_HEADING
   : IDENT PROCEDURE_PARTS
     {
         found("PROCEDURE_HEADING", $1);
         strcpy($$, $1);

     }
   ;

/* PROCEDURE_PARTS */
/* Formal parameter part (FORMAL_PARAMETER_PART), followed by optional
   mode part (OPT_MODE_PART), and by specification part (SPECIFICATION_PART) */
PROCEDURE_PARTS  
   : FORMAL_PARAMETER_PART OPT_MODE_PART SPECIFICATION_PART
   ;

/* PROCEDURE_BODY */
/* Statement (STATEMENT) */
PROCEDURE_BODY
   : STATEMENT
   ;

/* OBJECT_GENERATOR */
/* Keyword new, identifier, amd optional actual parameter part
   (OPT_ACTUAL_PARAMETER_PART) */
OBJECT_GENERATOR
   : KW_NEW IDENT OPT_ACTUAL_PARAMETER_PART
   ;

/* OPT_MODE_PART */
/* Empty */
OPT_MODE_PART
   : %empty
   | "mode"
   ;

/* DUMMY_STATEMENT */
/* Empty */
DUMMY_STATEMENT
   : %empty
   ;

/* SIMPLE_VARIABLE_DECLARATION */
/* Type (TYPE), followed by a type list (TYPE_LIST) */
SIMPLE_VARIABLE_DECLARATION
   : TYPE TYPE_LIST
   ;

/* TYPE_LIST */
/* A comma-separated list of type list elements (TYPE_LIST_ELEMENT) */
TYPE_LIST
   : TYPE_LIST_ELEMENT
   | TYPE_LIST ',' TYPE_LIST_ELEMENT
   ;

/* TYPE_LIST_ELEMENT */
/* Either identifier or a constant element (CONSTANT_ELEMENT) */
TYPE_LIST_ELEMENT
   : IDENT
   | CONSTANT_ELEMENT
   ;

/* CONSTANT_ELEMENT */
/* Identifier followed by an equal sign and value or text expression
   (VALUE_OR_TEXT_EXPRESSION) */
CONSTANT_ELEMENT
   : IDENT '=' VALUE_OR_TEXT_EXPRESSION
   ;

/* VALUE_OR_TEXT_EXPRESSION */
/* Either a value expression (VALUE_EXPRESSION) or text expression
   (TEXT_EXPRESSION) */
VALUE_OR_TEXT_EXPRESSION
   : VALUE_EXPRESSION
   | TEXT_EXPRESSION
   ;

/* FOR_STATEMENT */
/* Keyword for, followed by identifier, right part of for statement
   (FOR_RIGHT_PART), keyword do, and a statement (STATEMENT) */
FOR_STATEMENT
   : KW_FOR IDENT FOR_RIGHT_PART KW_DO STATEMENT { found("FOR_STATEMENT",$2); found("STATEMENT",""); }
   ;

/* FOR_RIGHT_PART */
/* Either assignment operator followed by value for list elements
   (VALUE_FOR_LIST_ELEMENTS),
   or: reference assign operator followed by reference for list elements
   (REFERENCE_FOR_LIST_ELEMENTS) */
FOR_RIGHT_PART
   : ASSIGN VALUE_FOR_LIST_ELEMENTS
   | REF_ASSIGN REFERENCE_FOR_LIST_ELEMENTS
   ;

/* VALUE_FOR_LIST_ELEMENTS */
/* A comma-separated list of value for list elements (VALUE_FOR_LIST_ELEMENT) */
VALUE_FOR_LIST_ELEMENTS
   : VALUE_FOR_LIST_ELEMENT
   | VALUE_FOR_LIST_ELEMENTS ',' VALUE_FOR_LIST_ELEMENT
   ;

/* VALUE_FOR_LIST_ELEMENT */
/* Either: a value expression (VALUE_EXPRESSION) followed by optional while
   (OPT_WHILE),
   or: arithmetic expression (ARITHMETIC_EXPRESSION), followed by keyword
   step, arithmetic expression, keyword until, and an arithmetic expression */
VALUE_FOR_LIST_ELEMENT
   : VALUE_EXPRESSION OPT_WHILE
   | ARITHMETIC_EXPRESSION KW_STEP ARITHMETIC_EXPRESSION KW_UNTIL ARITHMETIC_EXPRESSION
   ;

/* REFERENCE_FOR_LIST_ELEMENTS */
/* A comma-separated list of reference for list elements
   (REFERENCE_FOR_LIST_ELEMENT) */
REFERENCE_FOR_LIST_ELEMENTS
   : REFERENCE_FOR_LIST_ELEMENT
   | REFERENCE_FOR_LIST_ELEMENTS ',' REFERENCE_FOR_LIST_ELEMENT
   ;

/* REFERENCE_FOR_LIST_ELEMENT */
/* A reference expression (REFERENCE_EXPRESSION), followed by optional while
   (OPT_WHILE) */
REFERENCE_FOR_LIST_ELEMENT
   : REFERENCE_EXPRESSION OPT_WHILE
   ;

/* OPT_WHILE */
/* Empty */
OPT_WHILE
   : %empty
   | "while"
   ;

/* ARRAY_DECLARATION */
/* Optional type (OPT_TYPE), keyword array, and array segments
   (ARRAY_SEGMENTS) */
ARRAY_DECLARATION
   : OPT_TYPE KW_ARRAY ARRAY_SEGMENTS
   ;

/* ARRAY_SEGMENTS */
/* A comma-separated list of array segments (ARRAY_SEGMENT) */
ARRAY_SEGMENTS
   : ARRAY_SEGMENT 
   | ARRAY_SEGMENTS ',' ARRAY_SEGMENT
   ;

/* ARRAY_SEGMENT */
/* A list of identifiers (IDENTIFIER_LIST). followed by a list of bound pairs
   (BOUND_PAIR_LIST) in parentheses */
ARRAY_SEGMENT
   : IDENTIFIER_LIST '(' BOUND_PAIR_LIST ')' 
   ;

/* BOUND_PAIR_LIST */
/* A comma-separated list of bound pairs (BOUND_PAIR) */
BOUND_PAIR_LIST
   : BOUND_PAIR 
   | BOUND_PAIR_LIST ',' BOUND_PAIR
   ;

/* BOUND_PAIR */
/* Two arithmetic expressions separated with a colon */
BOUND_PAIR
   : ARITHMETIC_EXPRESSION ':' ARITHMETIC_EXPRESSION
   ;
%%


int main( void )
{
	int ret;
	yydebug = 1;
	printf( "Author: Jakub Szymczyk\n" );
	printf( "yytext              Token type      Token value as string\n\n" );
	ret = yyparse();
	return ret;
}

void yyerror(const char *txt)
{
	printf("Syntax error %s\n", txt);
}

void found(const char *nonterminal, const char *value)
{ /* info on syntax structures found */
	printf( "======== FOUND: %s %s%s%s ========\n", nonterminal, 
		(*value) ? "'" : "", value, (*value) ? "'" : "" );
}
