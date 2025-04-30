%code {
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include "types.h"
    #include "dict.h"
    #include "linked_list.h"

    void yyerror (const char *s);

    extern int yylineno;
    int temp_count = 0;
    dict symbols_table;
    struct linked_list* generated_commands = NULL;
    #define NO_VAL -1
    #define COMMAND_LENGTH 200
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
                        append_value(generated_commands, "HALT");
                        append_value(generated_commands, "Created by Or Dabool");

                        printf("\n---------------------------------------------\n");
                        printf("Program complete, cleaning up..\n");

                        printf("\nSymbols table:\n");
                        print_dict(symbols_table);
                        free_dict(symbols_table);
                        printf("Symbols table freed\n");

                        printf("\nTotal commands: %d\n", count_linked_list(generated_commands));

                        printf("---------------------------------------------\n\n");
                        print_linked_list(generated_commands);

                        printf("\n");
                        free_linked_list(generated_commands);
                    }
                ;

declarations    :   declarations declaration
                |   /* empty */
                ;

declaration     :   idlist ':' type ';'
                    {
                        // Install all IDs with the type
                        struct list_node* current = $1->head;
                        while (current != NULL) {
                            install(symbols_table, current->value, $3, NO_VAL, false);
                            current = current->next;
                        }
                        free_linked_list($1);
                    }
                ;

type            :   INT { $$ = INT_CODE; }
                |   FLOAT { $$ = FLOAT_CODE; }
                ;

idlist          :   idlist ',' ID
                    {
                        $$ = append_value($1, $3);
                    }
                |   ID
                    {
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
                            install(symbols_table, $1, var->type, var->val, false);
                        }
                    }
                ;

input_stmt      :   INPUT '(' ID ')' ';'
                    {
                        struct dict_item* var = lookup(symbols_table, $3);

                        if (var == NULL) {
                            fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                        } else {
                            char command[COMMAND_LENGTH];
                            if (var->type == INT_CODE) {
                                sprintf(command, "IINP %s", $3);
                            } else {
                                sprintf(command, "RINP %s", $3);
                            }
                            generated_commands = append_value(generated_commands, command);
                        }
                    }
                ;

output_stmt     :   OUTPUT '(' expression ')' ';'
                ;

if_stmt         :   IF '(' boolexpr ')' stmt ELSE stmt
                    {
                        struct dict_item* cond = lookup(symbols_table, $3);
                        if (cond == NULL) {
                            fprintf(stderr, "line %d: Internal error: boolean result not found\n", yylineno);
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
                        // TODO: use this logic for OR:
                        // (a + b) > 0 ? 1 : 0;
                        sprintf($$, "T%d", temp_count++);
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            install(symbols_table, $$, INT_CODE, 0, false);
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
                |   boolterm
                ;

boolterm        :   boolterm AND boolfactor
                    {
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            sprintf($$, "T%d", temp_count++);
                            char command[COMMAND_LENGTH];
                            bool is_const = a->is_const && b->is_const;

                            // multiply the boolean values to get the && result
                            float res = is_const ? a->val * b->val : NO_VAL;
                            sprintf(command, "IADD %s %s %s", $$, $1, $3);
                            install(symbols_table, $$, INT_CODE, (int)res, is_const);
                            append_value(generated_commands, command);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                strcpy($$, $1);
                            }
                        }
                    }
                |   boolfactor
                ;

boolfactor      :   NOT '(' boolexpr ')'
                    {
                        struct dict_item* var = lookup(symbols_table, $3);
                        if (var != NULL) {
                            sprintf($$, "T%d", temp_count++);
                            char command[COMMAND_LENGTH];

                            // Using (1.0 - var->val) to invert the boolean value of var
                            float res = var->is_const ? 1.0 - var->val : NO_VAL;

                            install(symbols_table, $$, INT_CODE, res, var->is_const);
                            // TODO: This is not a valid command in the assignment - need to fix - maybe ask about it
                            // TODO: Load the int 1, and then subtract the var->val as I did for res
                            sprintf(command, "NOT %s %s", $$, $3);
                            append_value(generated_commands, command);
                        } else {
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            strcpy($$, $3);
                        }
                    }
                |   expression RELOP expression
                    {
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            sprintf($$, "T%d", temp_count++);
                            char command[COMMAND_LENGTH];
                            bool is_const = a->is_const && b->is_const;

                            float res = NO_VAL;
                            switch ($2) {
                                case EQ:
                                    res = is_const ? a->val == b->val : NO_VAL;
                                    sprintf(command, "XEQL");
                                    break;
                                case NEQ:
                                    res = is_const ? a->val != b->val : NO_VAL;
                                    sprintf(command, "XNQL");
                                    break;
                                case LT:
                                    res = is_const ? a->val < b->val : NO_VAL;
                                    sprintf(command, "XLSS");
                                    break;
                                case GT:
                                    res = is_const ? a->val > b->val : NO_VAL;
                                    sprintf(command, "XGRT");
                                    break;
                                case GTE:
                                    res = is_const ? a->val >= b->val : NO_VAL;
                                    sprintf(command, "XGEQ");
                                    break;
                                case LTE:
                                    res = is_const ? a->val <= b->val : NO_VAL;
                                    sprintf(command, "XLEQ");
                                    break;
                            }

                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                command[0] = 'R';
                                if (a->type == INT_CODE) {
                                    char cast_command[COMMAND_LENGTH];
                                    sprintf(cast_command, "ITOR %s %s", $$, a->name);
                                    append_value(generated_commands, cast_command);
                                    a = install(symbols_table, $$, FLOAT_CODE, a->val, is_const);
                                    sprintf($$, "T%d", temp_count++);
                                }
                                if (b->type == INT_CODE) {
                                    char cast_command[COMMAND_LENGTH];
                                    sprintf(cast_command, "ITOR %s %s", $$, a->name);
                                    append_value(generated_commands, cast_command);
                                    b = install(symbols_table, $$, FLOAT_CODE, b->val, is_const);
                                    sprintf($$, "T%d", temp_count++);
                                }
                                install(symbols_table, $$, INT_CODE, res, is_const);
                            } else {
                                command[0] = 'I';
                                install(symbols_table, $$, INT_CODE, (int)res, is_const);
                            }

                            sprintf(command + strlen(command), " %s %s %s", $$, a->name, b->name);
                            append_value(generated_commands, command);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                strcpy($$, $1);
                            }
                        }
                    }
                ;

expression      :   expression ADDOP term
                    {
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            sprintf($$, "T%d", temp_count++);
                            char command[COMMAND_LENGTH];
                            bool is_const = a->is_const && b->is_const;

                            float res = NO_VAL;
                            if ($2 == ADD) {
                                res = is_const ? a->val + b->val : NO_VAL;
                                sprintf(command, "XADD");
                            } else {
                                res = is_const ? a->val - b->val : NO_VAL;
                                sprintf(command, "XSUB");
                            }

                            if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                command[0] = 'R';
                                if (a->type == INT_CODE) {
                                    char cast_command[COMMAND_LENGTH];
                                    sprintf(cast_command, "ITOR %s %s", $$, a->name);
                                    append_value(generated_commands, cast_command);
                                    a = install(symbols_table, $$, FLOAT_CODE, a->val, is_const);
                                    sprintf($$, "T%d", temp_count++);
                                }
                                if (b->type == INT_CODE) {
                                    char cast_command[COMMAND_LENGTH];
                                    sprintf(cast_command, "ITOR %s %s", $$, a->name);
                                    append_value(generated_commands, cast_command);
                                    b = install(symbols_table, $$, FLOAT_CODE, b->val, is_const);
                                    sprintf($$, "T%d", temp_count++);
                                }
                                install(symbols_table, $$, FLOAT_CODE, res, is_const);
                            } else {
                                command[0] = 'I';
                                install(symbols_table, $$, INT_CODE, (int)res, is_const);
                            }

                            sprintf(command + strlen(command), " %s %s %s", $$, a->name, b->name);
                            append_value(generated_commands, command);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                strcpy($$, $1);
                            }
                        }
                    }
                |   term
                ;

term            :   term MULOP factor
                    {
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            if ($2 == DIV && b->is_const && b->val == 0) {
                                fprintf(stderr, "line %d: Division by zero\n", yylineno);
                                strcpy($$, $1);
                            } else {
                                sprintf($$, "T%d", temp_count++);
                                char command[COMMAND_LENGTH];
                                bool is_const = a->is_const && b->is_const;

                                float res = NO_VAL;
                                if ($2 == MUL) {
                                    res = is_const ? a->val * b->val : NO_VAL;
                                    sprintf(command, "XMLT");
                                } else {
                                    res = is_const ? a->val / b->val : NO_VAL;
                                    sprintf(command, "XDIV");
                                }

                                if (a->type == FLOAT_CODE || b->type == FLOAT_CODE) {
                                    command[0] = 'R';
                                    if (a->type == INT_CODE) {
                                        char cast_command[COMMAND_LENGTH];
                                        sprintf(cast_command, "ITOR %s %s", $$, a->name);
                                        append_value(generated_commands, cast_command);
                                        a = install(symbols_table, $$, FLOAT_CODE, a->val, is_const);
                                        sprintf($$, "T%d", temp_count++);
                                    }
                                    if (b->type == INT_CODE) {
                                        char cast_command[COMMAND_LENGTH];
                                        sprintf(cast_command, "ITOR %s %s", $$, a->name);
                                        append_value(generated_commands, cast_command);
                                        b = install(symbols_table, $$, FLOAT_CODE, b->val, is_const);
                                        sprintf($$, "T%d", temp_count++);
                                    }
                                    install(symbols_table, $$, FLOAT_CODE, res, is_const);
                                } else {
                                    command[0] = 'I';
                                    install(symbols_table, $$, INT_CODE, (int)res, is_const);
                                }

                                sprintf(command + strlen(command), " %s %s %s", $$, a->name, b->name);
                                append_value(generated_commands, command);
                            }
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                strcpy($$, $1);
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
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            strcpy($$, $3);
                        } else {
                            char command[COMMAND_LENGTH];
                            if (var->type == INT_CODE && $1 == CASTF) {
                                sprintf($$, "T%d", temp_count++);
                                sprintf(command, "ITOR %s %s", $$, $3);
                                append_value(generated_commands, command);
                                install(symbols_table, $$, INT_CODE, (int)var->val, false);
                            } else if (var->type == FLOAT_CODE && $1 == CASTI) {
                                sprintf($$, "T%d", temp_count++);
                                sprintf(command, "RTOI %s %s", $$, $3);
                                append_value(generated_commands, command);
                                install(symbols_table, $$, FLOAT_CODE, var->val, false);
                            } else {
                                strcpy($$, $3);
                            }
                        }
                    }
                |   ID { strcpy($$, $1); }
                |   NUM
                    {
                        sprintf($$, "T%d", temp_count++);
                        char command[COMMAND_LENGTH];
                        if ($1.attr == FLOAT_CODE) {
                            sprintf(command, "RASN %s %f", $$, $1.val);
                            install(symbols_table, $$, FLOAT_CODE, $1.val, true);
                        } else {
                            sprintf(command, "IASN %s %d", $$, (int)$1.val);
                            install(symbols_table, $$, INT_CODE, (int)$1.val, true);
                        }
                        append_value(generated_commands, command);
                    }
                ;

%%

void yyerror (const char *s) {
    fprintf (stderr, "line %d: %s\n", yylineno, s);
}

