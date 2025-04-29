%code {
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include "types.h"
    #include "dict.h"
    #include "linked_list.h"

    extern int yylineno;

    void yyerror (const char *s);

    int temp_count = 0;

    dict symbols_table;
}

%code requires {
    struct number {
        int attr;
        float val;
    };
}

%union {
    int attr;
    struct number num;
    char id [50];
    struct linked_list* id_list;
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

%type <id> factor expression term boolfactor boolexpr boolterm
%type <attr> type
%type <id_list> idlist

%%

program         :   declarations stmt_block
                    {
                        printf("Program complete\n");

                        printf("\nSymbols table:\n");
                        print_dict(symbols_table);
                        printf("\n");

                        // Free the symbols table
                        free_dict(symbols_table);
                        printf("Symbols table freed\n");
                    }
                ;

declarations    :   declarations declaration
                |   /* empty */
                ;

declaration     :   idlist ':' type ';'
                    {
                        printf("Processing declaration with type: %d\n", $3);
                        // Install all IDs with the type
                        struct list_node* current = $1->head;
                        while (current != NULL) {
                            printf("Installing ID: %s with type: %d and value: %f\n", current->value, $3, 1.0);
                            install(symbols_table, current->value, $3, 1.0);
                            current = current->next;
                        }
                        free_linked_list($1);
                        printf("List freed\n");
                        printf("Declaration complete\n");
                    }
                ;

type            :   INT { $$ = INT_CODE; }
                |   FLOAT { $$ = FLOAT_CODE; }
                ;

idlist          :   idlist ',' ID
                    {
                        printf("Processing multiple IDs, current ID: %s\n", $3);
                        $$ = append_value($1, $3);
                    }
                |   ID
                    {
                        printf("Processing single ID: %s\n", $1);
                        $$ = new_linked_list($1);
                    }
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
                        struct dict_item* var = lookup(symbols_table, $1);
                        if (var == NULL) {
                            fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                        } else {
                            install(symbols_table, $1, var->type, var->val);
                        }
                    }
                ;

input_stmt      :   INPUT '(' ID ')' ';'
                ;

output_stmt     :   OUTPUT '(' expression ')' ';'
                ;

if_stmt         :   IF '(' boolexpr ')' stmt ELSE stmt
                    {
                        printf("Processing if statement with condition: %s\n", $3);
                        struct dict_item* cond = lookup(symbols_table, $3);
                        if (cond == NULL) {
                            fprintf(stderr, "line %d: Internal error: boolean result not found\n", yylineno);
                            YYERROR;
                        } else {
                            printf("Found condition variable with type %d\n", cond->type);
                        }
                    }
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
                    {
                        printf("Processing OR operation\n");
                        sprintf($$, "T%d", temp_count++);
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            install(symbols_table, $$, INT_CODE, 0);
                            fprintf(stdout, "OR %s %s %s\n", $$, $1, $3);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            }
                        }
                    }
                |   boolterm { strcpy($$, $1); }
                ;

boolterm        :   boolterm AND boolfactor
                    {
                        printf("Processing AND operation\n");
                        sprintf($$, "T%d", temp_count++);
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            install(symbols_table, $$, INT_CODE, 0);
                            fprintf(stdout, "AND %s %s %s\n", $$, $1, $3);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            }
                        }
                    }
                |   boolfactor { strcpy($$, $1); }
                ;

boolfactor      :   NOT '(' boolexpr ')' { }
                |   expression RELOP expression
                    {
                        sprintf($$, "T%d", temp_count++);
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            // printf("a=%p, b=%p\n", (void*)a, (void*)b);
                            // Always install boolean results as INT_CODE
                            install(symbols_table, $$, INT_CODE, 0);
                            // But use float comparison if either operand is float
                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                switch ($2) {
                                    case EQ:
                                        fprintf (stdout, "REQL %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case NEQ:
                                        fprintf (stdout, "RNQL %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case LT:
                                        fprintf (stdout, "RLSS %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case GT:
                                        fprintf (stdout, "RGRT %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case GTE:
                                        fprintf (stdout, "RGEQ %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case LTE:
                                        fprintf (stdout, "RLEQ %s %s %s\n", $$, a->name, b->name);
                                        break;
                                }
                            } else {
                                switch ($2) {
                                    case EQ:
                                        fprintf (stdout, "IEQL %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case NEQ:
                                        fprintf (stdout, "INQL %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case LT:
                                        fprintf (stdout, "ILSS %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case GT:
                                        fprintf (stdout, "IGRT %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case GTE:
                                        fprintf (stdout, "IGEQ %s %s %s\n", $$, a->name, b->name);
                                        break;
                                    case LTE:
                                        fprintf (stdout, "ILEQ %s %s %s\n", $$, a->name, b->name);
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
                        sprintf($$, "T%d", temp_count++);
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            float res;
                            if ($2 == ADD) {
                                res = a->val + b->val;
                            } else {
                                res = a->val - b->val;
                            }

                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                install(symbols_table, $$, FLOAT_CODE, res);
                            } else {
                                install(symbols_table, $$, INT_CODE, (int)res);
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
                        sprintf($$, "T%d", temp_count++);
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            // TODO: Why the fuck am I calculating the val? it's only good for constants! - should probably remove throughout everything
                            float res;
                            if ($2 == MUL) {
                                res = a->val * b->val;
                            } else {
                                res = a->val / b->val;
                            }

                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                install(symbols_table, $$, FLOAT_CODE, res);
                            } else {
                                install(symbols_table, $$, INT_CODE, (int)res);
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
                        struct dict_item* var = lookup(symbols_table, $3);
                        if (var == NULL) {
                            fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                        } else {
                            sprintf($$, "T%d", temp_count++);
                            if ($1 == CASTI) {
                                install(symbols_table, $$, INT_CODE, (int)var->val);
                            } else {
                                install(symbols_table, $$, FLOAT_CODE, var->val);
                            }
                        }
                    }
                |   ID { strcpy($$, $1); }
                |   NUM
                    {
                        sprintf($$, "T%d", temp_count++);
                        if ($1.attr == INT_CODE) {
                            fprintf (stdout, "IASN %s %d\n", $$, (int)$1.val);
                        } else {
                            fprintf (stdout, "RASN %s %f\n", $$, $1.val);
                        }
                        install(symbols_table, $$, $1.attr, $1.val);
                    }
                ;

%%

void yyerror (const char *s) {
    fprintf (stderr, "line %d: %s\n", yylineno, s);
}

