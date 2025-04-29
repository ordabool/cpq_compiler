%code {
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include "types.h"
    #include "dict.h"

    extern int yylineno;
    extern struct nlist *hashtab;

    void yyerror (const char *s);

    #define MAX_TEMP 100

    int tempCount = 0;
    int labelCount = 0;

    // TODO: Create a linked list file with appropriate header

    // Function implementations
    struct list_node* new_id_node(const char* id) {
        printf("Creating new node for ID: %s\n", id);
        struct list_node* node = (struct list_node*)malloc(sizeof(struct list_node));
        node->value = strdup(id);
        node->next = NULL;
        return node;
    }

    struct list_node* append_id(struct list_node* list, const char* id) {
        printf("Appending ID: %s\n", id);
        if (list == NULL) {
            return new_id_node(id);
        }
        // Find the last node
        struct list_node* current = list;
        while (current->next != NULL) {
            current = current->next;
        }
        // Append the new node
        current->next = new_id_node(id);
        return list;
    }

    void free_id_list(struct list_node* list) {
        printf("Freeing list\n");
        if (list == NULL) return;
        printf("Freeing node with ID: %s\n", list->value);
        struct list_node* next = list->next;  // Save next pointer before freeing
        // Don't free list->id since it's now owned by the hash table
        free(list);  // Only free the list node
        free_id_list(next);  // Process the rest of the list
    }
}

%code requires {
    struct number {
        int attr; // Type (INT_CODE, FLOAT_CODE, etc.)
        float val;
    };

    // Function declarations
    struct list_node* new_id_node(const char* id);
    struct list_node* append_id(struct list_node* list, const char* id);
}

%union {
    int attr;
    struct number num;
    char id [50];
    struct list_node* id_list;
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
                ;

declarations    :   declarations declaration
                |   /* empty */
                ;

declaration     :   idlist ':' type ';'
                    {
                        printf("Processing declaration with type: %d\n", $3);
                        // Install all IDs with the type
                        struct list_node* current = $1;
                        while (current != NULL) {
                            printf("Installing ID: %s with type: %d and value: %f\n", current->value, $3, 1.0);
                            install(current->value, $3, 1.0);
                            current = current->next;
                        }
                        free_id_list($1);  // Free the list after we're done
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
                        $$ = append_id($1, $3);
                    }
                |   ID
                    {
                        printf("Processing single ID: %s\n", $1);
                        $$ = new_id_node($1);
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
                    {
                        printf("Processing if statement with condition: %s\n", $3);
                        struct nlist* cond = lookup($3);
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
                        if (tempCount >= MAX_TEMP) {
                            fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                            YYERROR;
                        }
                        sprintf($$, "T%d", tempCount++);
                        struct nlist* a = lookup($1);
                        struct nlist* b = lookup($3);
                        if (a != NULL && b != NULL) {
                            install($$, INT_CODE, 0);
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
                        if (tempCount >= MAX_TEMP) {
                            fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                            YYERROR;
                        }
                        sprintf($$, "T%d", tempCount++);
                        struct nlist* a = lookup($1);
                        struct nlist* b = lookup($3);
                        if (a != NULL && b != NULL) {
                            install($$, INT_CODE, 0);
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
                        if (tempCount >= MAX_TEMP) {
                            fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                            YYERROR;
                        }
                        sprintf($$, "T%d", tempCount++);
                        struct nlist* a = lookup($1);
                        struct nlist* b = lookup($3);
                        if (a != NULL && b != NULL) {
                            // printf("a=%p, b=%p\n", (void*)a, (void*)b);
                            // Always install boolean results as INT_CODE
                            install($$, INT_CODE, 0);
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
                        if (tempCount >= MAX_TEMP) {
                            fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                            YYERROR;
                        }
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
                        if (tempCount >= MAX_TEMP) {
                            fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                            YYERROR;
                        }
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
                            if (tempCount >= MAX_TEMP) {
                                fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                                YYERROR;
                            }
                            sprintf($$, "T%d", tempCount++);
                            if ($1 == CASTI) {
                                install($$, INT_CODE, (int)var->val);
                            } else {
                                install($$, FLOAT_CODE, var->val);
                            }
                        }
                    }
                |   ID { strcpy($$, $1); }
                |   NUM
                    {
                        if (tempCount >= MAX_TEMP) {
                            fprintf(stderr, "line %d: Too many temporary variables!\n", yylineno);
                            YYERROR;
                        }
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

