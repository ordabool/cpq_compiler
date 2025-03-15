%code {
    #include <stdio.h>
    #include <string.h>
    #include "types.h"
    extern int yylineno;

    void yyerror (const char *s);

    // struct data init (struct data d);
}

%code requires {
    struct number {
        int attr;
        float val;
    };

    struct data {
        int type;
        struct number num;
        char id [80];
    };
}

%union {
    int attr;
    struct number num;
    char id [80];
    struct data d;
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

%type <d> factor expression term

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
                        // TODO: Need to check if result should be integer or real
                        switch ($2) {
                            case EQ:
                                fprintf (stdout, "IEQL t exp1 exp2\n");
                                break;
                            case NEQ:
                                fprintf (stdout, "INQL t exp1 exp2\n");
                                break;
                            case LT:
                                fprintf (stdout, "ILSS t exp1 exp2\n");
                                break;
                            case GT:
                                fprintf (stdout, "IGRT t exp1 exp2\n");
                                break;
                        }
                    }
                ;

expression      :   expression ADDOP term
                    {
                        if ($1.type != T_NUMBER || $3.type != T_NUMBER) {
                            fprintf (stderr, "line %d: Operator is allowed only between 2 numeric values\n", yylineno);
                        } else {
                            $$.type = T_NUMBER;
                            if ($1.num.attr == FLOAT_CODE || $3.num.attr == FLOAT_CODE) {
                                $$.num.attr == FLOAT_CODE;
                                if ($2 == ADD) {
                                    $$.num.val = $1.num.val + $3.num.val;
                                } else {
                                    $$.num.val = $1.num.val - $3.num.val;
                                }
                            } else {
                                $$.num.attr == INT_CODE;
                                if ($2 == ADD) {
                                    $$.num.val = (int)($1.num.val + $3.num.val);
                                } else {
                                    $$.num.val = (int)($1.num.val - $3.num.val);
                                }
                            }
                        }
                    }
                |   term
                ;

term            :   term MULOP factor
                    {
                        if ($1.type != T_NUMBER || $3.type != T_NUMBER) {
                            fprintf (stderr, "line %d: Operator is allowed only between 2 numeric values\n", yylineno);
                        } else {
                            $$.type = T_NUMBER;
                            if ($1.num.attr == FLOAT_CODE || $3.num.attr == FLOAT_CODE) {
                                $$.num.attr == FLOAT_CODE;
                                if ($2 == MUL) {
                                    $$.num.val = $1.num.val * $3.num.val;
                                } else {
                                    $$.num.val = $1.num.val / $3.num.val;
                                }
                            } else {
                                $$.num.attr == INT_CODE;
                                if ($2 == MUL) {
                                    $$.num.val = (int)($1.num.val * $3.num.val);
                                } else {
                                    $$.num.val = (int)($1.num.val / $3.num.val);
                                }
                            }
                        }
                    }
                |   factor
                ;

factor          :   '(' expression ')' { $$ = $2; }
                |   CAST '(' expression ')'
                    {
                        if ($3.type != T_NUMBER) {
                            fprintf (stderr, "line %d: Using cast on non-numeric value\n", yylineno);
                        } else {
                            $$ = $3;
                            if ($1 == CASTI) {
                                $$.num.attr = INT_CODE;
                                $$.num.val = (int)$3.num.val;
                            } else {
                                $$.num.attr = FLOAT_CODE;
                                $$.num.val = (float)$3.num.val;
                            }
                        }
                    }
                |   ID { $$.type = T_ID; strcpy($$.id, $1); }
                |   NUM { $$.type = T_NUMBER; $$.num = $1; }
                ;

%%

void yyerror (const char *s) {
    fprintf (stderr, "line %d: %s\n", yylineno, s);
}

/* struct data init (struct data d) {
    d.type = -1;
} */