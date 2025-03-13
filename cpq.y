%code {
    #include <stdio.h>
    extern int yylineno;

    void yyerror (const char *s);
}

%union {
    int attr;
    struct {
        int attr;
        int intVal;
        float floatVal;
    } num;
    char id [80];
}

%define parse.error verbose

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
%token <attr> RELOP
%token <attr> ADDOP
%token <attr> MULOP
%token OR
%token AND
%token NOT
%token <attr> CAST
%token <id> ID
%token <num> NUM

/* TODO: this is the syntax to specify the type of non-terminals */
/* %type <attr> expression boolfactor */

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
                    {
                        fprintf (stdout, "boolfactor spotted at line %d! Att: %d\n", yylineno, $2);
                    }
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
    fprintf (stderr, "line %d: %s\n", yylineno, s);
}