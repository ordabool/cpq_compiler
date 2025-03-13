%{

#include "cpq.tab.h"

#define EQ                      10
#define NEQ                     11
#define LT                      12
#define GT                      13
#define GTE                     14
#define LTE                     15
#define ADD                     16
#define SUB                     17
#define MUL                     18
#define DIV                     19
#define CASTI                   20
#define CASTF                   21
#define INT_CODE                22
#define FLOAT_CODE              23

%}

%option noyywrap
%option yylineno

%x COMMENT

symbol                          [(){},:;=]
digit                           [0-9]
letter                          [A-Za-z]

%%

"break"                         { return BREAK; }
"case"                          { return CASE; }
"default"                       { return DEFAULT; }
"else"                          { return ELSE; }
"float"                         { return FLOAT; }
"if"                            { return IF; }
"input"                         { return INPUT; }
"int"                           { return INT; }
"output"                        { return OUTPUT; }
"switch"                        { return SWITCH; }
"while"                         { return WHILE; }

{symbol}                        { return yytext[0]; }

"=="                            { return RELOP; }
"!="                            { return RELOP; }
"<"                             { return RELOP; }
">"                             { return RELOP; }
">="                            { return RELOP; }
"<="                            { return RELOP; }

"+"                             { return ADDOP; }
"-"                             { return ADDOP; }

"*"                             { return MULOP; }
"/"                             { return MULOP; }

"||"                            { return OR; }
"&&"                            { return AND; }
"!"                             { return NOT; }

"cast<int>"                     { return CAST; }
"cast<float>"                   { return CAST; }

{letter}({letter}|{digit})*     { return ID; }

{digit}+                        { return NUM; }
{digit}+"."{digit}*             { return NUM; }

"/""*"+                         { BEGIN(COMMENT); /* this is a start of a comment, so go to start condition */ }
<COMMENT>{
    "*"+"/"                     { BEGIN(0); /* comment ended, leave start condition */ }
    .                           { /* ignore the body of the comment */ } 
}

[\t\n ]+                        /* ignore spaces, tabs and newlines */

.                               { /* TODO: this rule is copied from the example, maybe I'll want to write it differently */
                                    fprintf (stderr, "line %d: unrecognized token %c\n", yylineno, yytext[0]);  /* TODO: See that I can access yylineno here */
                                    exit(1);
                                }

%%
