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

#define BREAK                   100
#define CASE                    101
#define DEFAULT                 102
#define ELSE                    103
#define FLOAT                   104
#define IF                      105
#define INPUT                   106
#define INT                     107
#define OUTPUT                  108
#define SWITCH                  109
#define WHILE                   110
#define RELOP                   111
#define ADDOP                   112
#define MULOP                   113
#define OR                      114
#define AND                     115
#define NOT                     116
#define CAST                    117
#define ID                      118
#define NUM                     119
#define SYMOBL                  120

%}

%option noyywrap
%option yylineno

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

{symbol}                        { return SYMOBL; }

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

[\t\n ]+                        /* ignore spaces, tabs and newlines */

.                               { /* TODO: this rule is copied from the example, maybe I'll want to write it differently */
                                    fprintf (stderr, "line %d: unrecognized token %c\n", yylineno, yytext[0]);  /* TODO: See that I can access yylineno here */
                                    exit(1);
                                }

%%
