%{
#include <stdio.h> /* printf() */
#include <string.h> /* strcpy */
#include <stdlib.h> /* atoi(), atof() */
#include "common.h" /* MAX_STR_LEN */
#include "simula.tab.h" /* declaration of terminals */

/* printing information about the terminal found */
int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID);

int str_beg = 0;  /* start line of a string */
int comm_beg = 0; /* start line of a comment */

typedef struct {
    const char *word;
    int token;
} Keyword;

Keyword keywords[] = {
    {"ACTIVATE", KW_ACTIVATE}, {"AFTER", KW_AFTER}, {"AND", KW_AND},
    {"ARRAY", KW_ARRAY}, {"AT", KW_AT}, {"BEFORE", KW_BEFORE},
    {"BEGIN", KW_BEGIN}, {"BOOLEAN", KW_BOOLEAN}, {"CHARACTER", KW_CHARACTER},
    {"CLASS", KW_CLASS}, {"DELAY", KW_DELAY}, {"DO", KW_DO},
    {"ELSE", KW_ELSE}, {"END", KW_END}, {"EQ", KW_EQ},
    {"EQV", KW_EQV}, {"EXTERNAL", KW_EXTERNAL}, {"FALSE", KW_FALSE},
    {"FOR", KW_FOR}, {"GE", KW_GE}, {"GO", KW_GO}, {"GOTO", KW_GOTO},
    {"GT", KW_GT}, {"HIDDEN", KW_HIDDEN}, {"IF", KW_IF}, {"IMP", KW_IMP},
    {"IN", KW_IN}, {"INNER", KW_INNER}, {"INSPECT", KW_INSPECT},
    {"INTEGER", KW_INTEGER}, {"IS", KW_IS}, {"LABEL", KW_LABEL},
    {"LONG", KW_LONG}, {"LT", KW_LT}, {"NAME", KW_NAME}, {"NE", KW_NE},
    {"NEW", KW_NEW}, {"NONE", KW_NONE}, {"NOT", KW_NOT}, {"NOTEXT", KW_NOTEXT},
    {"OR", KW_OR}, {"OTHERWISE", KW_OTHERWISE}, {"PRIOR", KW_PRIOR},
    {"PROCEDURE", KW_PROCEDURE}, {"PROTECTED", KW_PROTECTED}, {"QUA", KW_QUA},
    {"REACTIVATE", KW_REACTIVATE}, {"REAL", KW_REAL}, {"REF", KW_REF},
    {"SHORT", KW_SHORT}, {"STEP", KW_STEP}, {"SWITCH", KW_SWITCH},
    {"TEXT", KW_TEXT}, {"THEN", KW_THEN}, {"THIS", KW_THIS}, {"TO", KW_TO},
    {"TRUE", KW_TRUE}, {"UNTIL", KW_UNTIL}, {"VALUE", KW_VALUE},
    {"VIRTUAL", KW_VIRTUAL}, {"WHEN", KW_WHEN}, {"WHILE", KW_WHILE},
    {NULL, 0}
};
%}

uint  [0-9]+|(2|4|8|16)[Rr][0-9A-Fa-f]+

%option yylineno

%x END_COMMENT DIRECT_COMMENT STRING
%%
 /* removal of white spaces */
[ \t\r\n]+    { /* ignore whitespace */ }

 /* detection of keywords and identifiers */
[A-Za-z_][A-Za-z0-9_]* {
  char token_name[64];
  int i;

  for (i = 0; keywords[i].word; i++) {
    if (strcasecmp(yytext, keywords[i].word) == 0) {
      strcpy(token_name, "KW_");
      strcat(token_name, keywords[i].word);

      if (strcasecmp(yytext, "END") == 0) {
        comm_beg = yylineno;
        BEGIN(END_COMMENT);
      }

      return process_token(yytext, token_name, "", keywords[i].token);
    }
  }
  return process_token(yytext, "IDENT", yytext, IDENT);
}

 /* multi-character operators */
":-"    { return process_token(yytext, "REF_ASSIGN", "", REF_ASSIGN); }
":="    { return process_token(yytext, "ASSIGN", "", ASSIGN); }
"<="    { return process_token(yytext, "KW_LE", "", KW_LE); }
">="    { return process_token(yytext, "KW_GE", "", KW_GE); }
"<>"    { return process_token(yytext, "REF_NE", "", REF_NE); }
"=="    { return process_token(yytext, "REF_EQ", "", REF_EQ); }

[0-9]+   { return process_token(yytext, "INTEGER_CONST", yytext, INTEGER_CONST); }
[0-9]+\.[0-9]+   { return process_token(yytext, "REAL_CONST", yytext, REAL_CONST); }

 /* direct comments */
"!" {
    comm_beg = yylineno;
    BEGIN(DIRECT_COMMENT);
}

<DIRECT_COMMENT>[^;\n]+    { /* ignore */ }
<DIRECT_COMMENT>";" { BEGIN(INITIAL); }
<DIRECT_COMMENT>\n { /* continue to next line */ }

 /* end comments */
<END_COMMENT>[^\n;]*   { /* ignore */ }
<END_COMMENT>";" {
    BEGIN(INITIAL);
    return process_token(yytext, yytext, "", yytext[0]);
}
<END_COMMENT>\n {
    	yywrap();
	BEGIN(INITIAL);
}

 /* strings */
\" {
    str_beg = yylineno;
    BEGIN(STRING);
    yymore();
}
<STRING>\"\" { yymore(); }
<STRING>\" {
    BEGIN(INITIAL);
    return process_token(yytext, "TEXT_CONST", "", TEXT_CONST);
}
<STRING>\n {
    	yywrap();
	BEGIN(INITIAL);
}
<STRING>. { yymore(); }

\'[^\']*\'    { return process_token(yytext, "CHARACTER_CONST", yytext, CHARACTER_CONST); }

 /* single character operators and punctuation */
[+\-*/=<>()[\]{},;:.]    { return process_token(yytext, yytext, "", yytext[0]); }
%%
int process_token(const char *text, const char *TokenType,
                  const char *TokenVal, const int TokenID) {
  int l;
  switch (TokenID) {
  case INTEGER_CONST:
    yylval.i = atoi(text); break;
  case REAL_CONST:
    yylval.d = atof(text); break;
  case IDENT:
    strncpy(yylval.s, text, MAX_STR_LEN); break;
  case TEXT_CONST:
    l = strlen(text);
    strncpy(yylval.s, text + 1, l - 2 <= MAX_STR_LEN ? l - 2 : MAX_STR_LEN);
    for (int i = 0; yylval.s[i]; i++) {
      if (yylval.s[i] == '"' && yylval.s[i+1] == '"') {
        memmove(yylval.s + i, yylval.s + i + 1, strlen(yylval.s + i));
      }
    }
    printf("%-20.20s%-15s %s\n", text, TokenType, yylval.s);
    return TokenID;
  case CHARACTER_CONST:
    yylval.i = text[1]; break;
  }
  printf("%-20.20s%-15s %s\n", text, TokenType, TokenVal);
  return TokenID;
}

int yywrap(void) {
  if (YY_START == DIRECT_COMMENT)
    fprintf(stderr, "Unfinished comment started in line %d\n", comm_beg);
  else if (YY_START == END_COMMENT)
    fprintf(stderr, "Missing semicolon after END in line %d\n", comm_beg);
  else if (YY_START == STRING)
    fprintf(stderr, "Unfinished string opened in line %d\n", str_beg);
  return 1;
}

