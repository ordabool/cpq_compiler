%{
    #include <stdio.h>
    void yyerror (const char *s);
%}

%token BREAK
%token CASE
%token DEFAULT
%token ELSE
%token FLOAT
%token IF
%token INPUT
%token INT
%token OUTPUT
%token SWITCH
%token WHILE
%token RELOP
%token ADDOP
%token MULOP
%token OR
%token AND
%token NOT
%token CAST
%token ID
%token NUM

%%

program         :   declarations stmt_block
                ;

declarations    :   declarations declaration
                |   /* empty */
                ;

declaration     :   idlist ':' type ';'
                ;

type            :   INT
                |   FLOAT
                ;

idlist          :   idlist ',' ID
                |   ID
                ;

stmt            :   assignment_stmt
                |   input_stmt
                |   output_stmt
                |   if_stmt
                |   while_stmt
                |   switch_stmt
                |   break_stmt
                |   stmt_block
                ;

assignment_stmt :   ID '=' expression ';'
                ;

input_stmt      :   INPUT '(' ID ')' ';'
                ;

output_stmt     :   OUTPUT '(' expression ')' ';'
                ;

if_stmt         :   IF '(' boolexpr ')' stmt ELSE stmt
                ;

while_stmt      :   WHILE '(' boolexpr ')' stmt
                ;

switch_stmt     :   SWITCH '(' expression ')' '{' caselist DEFAULT ':' stmtlist '}'
                ;

caselist        :   caselist CASE NUM ':' stmtlist
                |   /* empty */
                ;

break_stmt      :   BREAK ';'
                ;

stmt_block      :   '{' stmtlist '}'
                ;

stmtlist        :   stmtlist stmt
                |   /* empty */
                ;

boolexpr        :   boolexpr OR boolterm
                |   boolterm
                ;

boolterm        :   boolterm AND boolfactor
                |   boolfactor
                ;

boolfactor      :   NOT '(' boolexpr ')'
                |   expression RELOP expression
                ;

expression      :   expression ADDOP term
                |   term
                ;

term            :   term MULOP factor
                |   factor
                ;

factor          :   '(' expression ')'
                |   CAST '(' expression ')'
                |   ID
                |   NUM
                ;

%%

void yyerror (const char *s)
{
    fprintf (stderr, "%s\n", s);
}