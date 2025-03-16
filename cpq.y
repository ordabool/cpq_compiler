%code {
    #include <stdio.h>
    #include <string.h>
    #include "types.h"
    
    extern int yylineno;
    extern struct nlist* hashtab;

    void yyerror (const char *s);

    #define MAX_TEMP 100

    int tempCount = 0;
    int labelCount = 0;
}

%code requires {
    struct number {
        int attr; // Type (INT_CODE, FLOAT_CODE, etc.)
        float val;
    };
}

%union {
    int attr;
    struct number num;
    char id [20];
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

%type <id> factor expression term boolfactor
%type <attr> type

%%

program         :   declarations stmt_block
                ;

declarations    :   declarations declaration
                |   /* empty */
                ;

declaration     :   idlist ':' type ';'
                ;

type            :   INT { $$ = INT_CODE; }
                |   FLOAT { $$ = FLOAT_CODE; }
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
                    { 
                        struct nlist* var = lookup($1);
                        if (var == NULL) {
                            fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                        } else {
                            install($1, var->type, var->val);
                        }
                    }
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

boolfactor      :   NOT '(' boolexpr ')' { }
                |   expression RELOP expression
                    {
                        sprintf($$, "T%d", tempCount++);
                        struct nlist* a = lookup($1);
                        struct nlist* b = lookup($3);
                        if (a != NULL && b != NULL) {
                            install($$, INT_CODE, 0);
                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                switch ($2) {
                                    case EQ:
                                        fprintf (stdout, "REQL %s %s %s\n", $$, $1, $3);
                                        break;
                                    case NEQ:
                                        fprintf (stdout, "RNQL %s %s %s\n", $$, $1, $3);
                                        break;
                                    case LT:
                                        fprintf (stdout, "RLSS %s %s %s\n", $$, $1, $3);
                                        break;
                                    case GT:
                                        fprintf (stdout, "RGRT %s %s %s\n", $$, $1, $3);
                                        break;
                                    // TODO: I think I haven't covered all of the cases here - need to check the docs
                                }
                            } else {
                                switch ($2) {
                                    case EQ:
                                        fprintf (stdout, "IEQL %s %s %s\n", $$, $1, $3);
                                        break;
                                    case NEQ:
                                        fprintf (stdout, "INQL %s %s %s\n", $$, $1, $3);
                                        break;
                                    case LT:
                                        fprintf (stdout, "ILSS %s %s %s\n", $$, $1, $3);
                                        break;
                                    case GT:
                                        fprintf (stdout, "IGRT %s %s %s\n", $$, $1, $3);
                                        break;
                                }
                            }
                        } else {
                            if (a == NULL) {
                                fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                            }
                            if (b == NULL) {
                                fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            }
                        }
                    }
                ;

expression      :   expression ADDOP term
                    {
                        sprintf($$, "T%d", tempCount++);
                        struct nlist* a = lookup($1);
                        struct nlist* b = lookup($3);
                        if (a != NULL && b != NULL) {
                            float res;
                            if ($2 == ADD) {
                                res = a->val + b->val;
                            } else {
                                res = a->val - b->val;
                            }

                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                install($$, FLOAT_CODE, res);
                            } else {
                                install($$, INT_CODE, (int)res);
                            }
                        } else {
                            if (a == NULL) {
                                fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                            }
                            if (b == NULL) {
                                fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            }
                        }
                    }
                |   term
                ;

term            :   term MULOP factor
                    {
                        sprintf($$, "T%d", tempCount++);
                        struct nlist* a = lookup($1);
                        struct nlist* b = lookup($3);
                        if (a != NULL && b != NULL) {
                            // TODO: Why the fuck am I calculating the val? it's only good for constants! - should probably remove throughout everything
                            float res;
                            if ($2 == MUL) {
                                res = a->val * b->val;
                            } else {
                                res = a->val / b->val;
                            }

                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                install($$, FLOAT_CODE, res);
                            } else {
                                install($$, INT_CODE, (int)res);
                            }
                        } else {
                            if (a == NULL) {
                                fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                            }
                            if (b == NULL) {
                                fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            }
                        }
                    }
                |   factor
                ;

factor          :   '(' expression ')' { strcpy($$, $2); }
                |   CAST '(' expression ')'
                    {
                        struct nlist* var = lookup($3);
                        if (var == NULL) {
                            fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                        } else {
                            sprintf($$, "T%d", tempCount++);
                            if ($1 == CASTI) {
                                install($$, INT_CODE, (int)var->val);
                            } else {
                                install($$, FLOAT_CODE, var->val);
                            }
                        }
                    }
                |   ID
                |   NUM
                    {
                        sprintf($$, "T%d", tempCount++);
                        if ($1.attr == INT_CODE) {
                            fprintf (stdout, "IASN %s %d\n", $$, (int)$1.val);
                        } else {
                            fprintf (stdout, "RASN %s %f\n", $$, $1.val);
                        }
                        install($$, $1.attr, $1.val);
                    }
                ;

%%

void yyerror (const char *s) {
    fprintf (stderr, "line %d: %s\n", yylineno, s);
}
