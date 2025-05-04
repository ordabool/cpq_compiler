%{

#include "cpq.tab.h"
#include "types.h"

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

"=="                            { yylval.attr = EQ; return RELOP; }
"!="                            { yylval.attr = NEQ; return RELOP; }
"<"                             { yylval.attr = LT; return RELOP; }
">"                             { yylval.attr = GT; return RELOP; }
">="                            { yylval.attr = GTE; return RELOP; }
"<="                            { yylval.attr = LTE; return RELOP; }

"+"                             { yylval.attr = ADD; return ADDOP; }
"-"                             { yylval.attr = SUB; return ADDOP; }

"*"                             { yylval.attr = MUL; return MULOP; }
"/"                             { yylval.attr = DIV; return MULOP; }

"||"                            { return OR; }
"&&"                            { return AND; }
"!"                             { return NOT; }

"cast<int>"                     { yylval.attr = CASTI; return CAST; }
"cast<float>"                   { yylval.attr = CASTF; return CAST; }

{letter}({letter}|{digit})*     { strcpy (yylval.id, yytext); return ID; }

{digit}+                        { yylval.num.attr = INT_CODE; yylval.num.val = atoi(yytext); return NUM; }
{digit}+"."{digit}*             { yylval.num.attr = FLOAT_CODE; yylval.num.val = atof(yytext); return NUM; }

"/""*"+                         { BEGIN(COMMENT); /* this is a start of a comment, so go to start condition */ }
<COMMENT>{
    "*"+"/"                     { BEGIN(0); /* comment ended, leave start condition */ }
    .                           /* ignore the body of the comment */
}

[\t\n ]+                        /* ignore spaces, tabs and newlines */

.                               {
                                    fprintf (stderr, "line %d: unrecognized token %c\n", yylineno, yytext[0]);
                                }

%%
