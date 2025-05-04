%code {
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include "types.h"
    #include "dict.h"
    #include "stack.h"
    #include "linked_list.h"

    void yyerror (char* output_file, const char* s);

    extern int yylineno;
    int temp_count = 0;
    dict symbols_table;
    struct linked_list* generated_commands = NULL;
    struct stack* backpatch_stack;
    #define NO_VAL -1
    #define COMMAND_LENGTH 200
    struct dict_item* one = NULL;
    struct dict_item* zero = NULL;
    bool error_flag = false;

    void backpatch(struct list_node* command_node, int address) {
        sprintf(command_node->value, command_node->value, address);
    }

    struct dict_item* get_one() {
        if (one == NULL) {
            char temp_name[50];
            sprintf(temp_name, "T%d", temp_count++);
            char assign_one_command[COMMAND_LENGTH];
            sprintf(assign_one_command, "IASN %s %d", temp_name, 1);
            append_value(generated_commands, assign_one_command);
            one = install(symbols_table, temp_name, INT_CODE, 1, true);
        }
        return one;
    }

    struct dict_item* get_zero() {
        if (zero == NULL) {
            char temp_name[50];
            sprintf(temp_name, "T%d", temp_count++);
            char assign_zero_command[COMMAND_LENGTH];
            sprintf(assign_zero_command, "IASN %s %d", temp_name, 0);
            append_value(generated_commands, assign_zero_command);
            zero = install(symbols_table, temp_name, INT_CODE, 0, true);
        }
        return zero;
    }
}

%code requires {
    struct number {
        int attr;
        float val;
    };
}
%parse-param {char* output_file}

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
                        // Add HALT and signature line to the generated commands
                        append_value(generated_commands, "HALT");
                        append_value(generated_commands, "Created by Or Dabool");

                        // If no errors, write the generated commands to the output file
                        if (!error_flag) {
                            FILE* output = fopen(output_file, "w");
                            if (output == NULL) {
                                fprintf(stderr, "Error opening output file %s\n", output_file);
                                exit(1);
                            }
                            struct list_node* current = generated_commands->head;
                            while (current != NULL) {
                                fprintf(output, "%s\n", current->value);
                                current = current->next;
                            }
                            fclose(output);
                        } else {
                            fprintf(stderr, "Errors found during parsing. No output file generated.\n");
                        }

                        // Program complete, cleaning up..
                        free_dict(symbols_table);
                        free_linked_list(generated_commands);
                        free_stack(backpatch_stack);
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
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            if (a->type == INT_CODE && b->type == FLOAT_CODE) {
                                fprintf(stderr, "line %d: Invalid assignment of float to int variable %s\n", yylineno, $1);
                                error_flag = true;
                            } else {
                                char command[COMMAND_LENGTH];
                                if (a->type == FLOAT_CODE) {
                                    if (b->type == INT_CODE) {
                                        sprintf($3, "T%d", temp_count++);

                                        char cast_command[COMMAND_LENGTH];
                                        sprintf(cast_command, "ITOR %s %s", $3, b->name);
                                        append_value(generated_commands, cast_command);
                                        b = install(symbols_table, $3, FLOAT_CODE, b->val, b->is_const);
                                    }
                                    sprintf(command, "RASN %s %s", $1, $3);
                                } else {
                                    sprintf(command, "IASN %s %s", $1, $3);
                                }
                                install(symbols_table, $1, a->type, b->val, b->is_const);
                                append_value(generated_commands, command);
                            }
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                error_flag = true;
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                error_flag = true;
                            }
                        }
                    }
                ;

input_stmt      :   INPUT '(' ID ')' ';'
                    {
                        struct dict_item* var = lookup(symbols_table, $3);

                        if (var == NULL) {
                            fprintf (stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            error_flag = true;
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
                    {
                        struct dict_item* var = lookup(symbols_table, $3);
                        if (var == NULL) {
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            error_flag = true;
                        } else {
                            char command[COMMAND_LENGTH];
                            if (var->type == INT_CODE) {
                                sprintf(command, "IPRT %s", $3);
                            } else {
                                sprintf(command, "RPRT %s", $3);
                            }
                            generated_commands = append_value(generated_commands, command);
                        }
                    }
                ;

if_stmt         :   IF '(' boolexpr ')'
                    {
                        struct dict_item* cond = lookup(symbols_table, $3);
                        if (cond == NULL) {
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            error_flag = true;
                            // In this case, to continue the parsing, set $3 as zero
                            zero = get_zero();
                            strcpy($3, zero->name);
                        }

                        char jump_command[COMMAND_LENGTH];
                        sprintf(jump_command, "JMPZ %%d %s", $3);
                        append_value(generated_commands, jump_command);
                        backpatch_stack = push_stack(backpatch_stack, generated_commands->tail);
                    }
                    stmt
                    {
                        char jump_command[COMMAND_LENGTH];
                        sprintf(jump_command, "JMP %%d");
                        append_value(generated_commands, jump_command);
                        backpatch_stack = push_stack(backpatch_stack, generated_commands->tail);
                    }
                    ELSE 
                    {
                        // here we need to backpatch the JMPZ command, but leave the last JMP command
                        // so we need to pop twice but push the first one back
                        struct list_node* jmp_command_node = pop_stack(backpatch_stack);
                        struct list_node* jmpz_command_node = pop_stack(backpatch_stack);

                        backpatch(jmpz_command_node, generated_commands->size + 1);
                        backpatch_stack = push_stack(backpatch_stack, jmp_command_node);
                    }
                    stmt
                    {
                        struct list_node* command_node = pop_stack(backpatch_stack);
                        backpatch(command_node, generated_commands->size + 1);
                    }
                ;

while_stmt      :   WHILE '('
                    {
                        // Add a flag to mark a while context
                        char* while_start_flag = "WHILE_START";
                        struct list_node* while_flag = new_list_node(while_start_flag);
                        backpatch_stack = push_stack(backpatch_stack, while_flag);

                        // we are using the backpatch stack to hold the command even though we don't need to backpatch it
                        // we just need to hold it until we reach the end of the while statement
                        char while_restart_command[COMMAND_LENGTH];
                        sprintf(while_restart_command, "JMP %d", generated_commands->size + 1);
                        struct list_node* while_restart = new_list_node(while_restart_command);
                        backpatch_stack = push_stack(backpatch_stack, while_restart);
                    }
                    boolexpr
                    {
                        struct dict_item* cond = lookup(symbols_table, $4);
                        if (cond == NULL) {
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $4);
                            error_flag = true;
                            // In this case, to continue the parsing, set $4 as zero
                            zero = get_zero();
                            strcpy($4, zero->name);
                        }

                        char jump_command[COMMAND_LENGTH];
                        sprintf(jump_command, "JMPZ %%d %s", $4);
                        append_value(generated_commands, jump_command);
                        backpatch_stack = push_stack(backpatch_stack, generated_commands->tail);
                    }
                    ')' stmt
                    {
                        // Pop all the elements until we reach the WHILE_START flag
                        struct stack* popped;
                        while (backpatch_stack->top > -1 && strcmp(backpatch_stack->stack_arr[backpatch_stack->top]->value, "WHILE_START") != 0) {
                            struct list_node* popped_node = pop_stack(backpatch_stack);
                            popped = push_stack(popped, popped_node);
                        }

                        // Pop switch_condition and switch_flag now that the switch is done
                        struct list_node* while_restart_node = pop_stack(popped);
                        append_value(generated_commands, while_restart_node->value);
                        struct list_node* while_flag = pop_stack(backpatch_stack);

                        // Backpatch all jumps (JMPZ of condition, or break JMP) in popped
                        while (popped->top > -1) {
                            struct list_node* popped_node = pop_stack(popped);
                            backpatch(popped_node, generated_commands->size + 1);
                        }
                    }
                ;

switch_stmt     :   SWITCH '(' expression ')'
                    {
                        struct dict_item* cond = lookup(symbols_table, $3);
                        if (cond == NULL) {
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            error_flag = true;
                            zero = get_zero();
                            strcpy($3, zero->name);
                        } else if (cond->type != INT_CODE) {
                            fprintf(stderr, "line %d: The variable %s is not an integer!\n", yylineno, $3);
                            error_flag = true;
                            zero = get_zero();
                            strcpy($3, zero->name);
                        }

                        char* switch_start_flag = "SWITCH_START";
                        struct list_node* switch_flag = new_list_node(switch_start_flag);
                        backpatch_stack = push_stack(backpatch_stack, switch_flag);

                        char switch_condition_command[COMMAND_LENGTH];
                        sprintf(switch_condition_command, "IEQL %%s %s %%d", $3);
                        struct list_node* switch_condition = new_list_node(switch_condition_command);
                        backpatch_stack = push_stack(backpatch_stack, switch_condition);
                    }
                    '{' caselist DEFAULT ':'
                    {
                        // Backpatch previous case if needed
                        struct stack* popped;
                        while (backpatch_stack->top > -1 && strcmp(backpatch_stack->stack_arr[backpatch_stack->top]->value, "CASE_START") != 0) {
                            struct list_node* popped_node = pop_stack(backpatch_stack);
                            popped = push_stack(popped, popped_node);
                        }

                        // If found a CASE_START flag, backpatch the previous case
                        if (backpatch_stack->top > -1) {
                            struct list_node* case_flag = pop_stack(backpatch_stack);
                            struct list_node* jump_to_backpatch = pop_stack(popped);
                            backpatch(jump_to_backpatch, generated_commands->size+1);
                        }

                        // Push all the popped elements back to the stack
                        while (popped != NULL && popped->top > -1) {
                            struct list_node* popped_node = pop_stack(popped);
                            backpatch_stack = push_stack(backpatch_stack, popped_node);
                        }
                    }
                    stmtlist 
                    {
                        // Pop all the elements until we reach the SWITCH_START flag
                        struct stack* popped;
                        while (backpatch_stack->top > -1 && strcmp(backpatch_stack->stack_arr[backpatch_stack->top]->value, "SWITCH_START") != 0) {
                            struct list_node* popped_node = pop_stack(backpatch_stack);
                            popped = push_stack(popped, popped_node);
                        }

                        // Pop switch_condition and switch_flag now that the switch is done
                        struct list_node* switch_condition = pop_stack(popped);
                        struct list_node* switch_flag = pop_stack(backpatch_stack);

                        // Backpatch all jumps in popped
                        while (popped->top > -1) {
                            struct list_node* popped_node = pop_stack(popped);
                            backpatch(popped_node, generated_commands->size + 1);
                        }
                    }
                    '}'
                ;

caselist        :   caselist CASE NUM ':'
                    {
                        // If the number is not an integer, or backpatch_stack is empty, do nothing
                        if ($3.attr == INT_CODE && backpatch_stack != NULL && backpatch_stack->top > -1) {

                            // Look for a SWITCH_START flag in the stack, to know that this is a valid case
                            for (int i = backpatch_stack->top; i > -1; i--) {
                                if (strcmp(backpatch_stack->stack_arr[i]->value, "SWITCH_START") == 0) {
                                    char temp_name[50];
                                    sprintf(temp_name, "T%d", temp_count++);

                                    // Add the switch comaprison command - IEQL
                                    char switch_condition_command[COMMAND_LENGTH];
                                    strcpy(switch_condition_command, backpatch_stack->stack_arr[i+1]->value);
                                    sprintf(switch_condition_command, switch_condition_command, temp_name, (int)$3.val);
                                    append_value(generated_commands, switch_condition_command);
                                    install(symbols_table, temp_name, INT_CODE, NO_VAL, false);

                                    // Backpatch previous case if needed
                                    struct stack* popped;
                                    while (backpatch_stack->top > -1 && strcmp(backpatch_stack->stack_arr[backpatch_stack->top]->value, "CASE_START") != 0) {
                                        struct list_node* popped_node = pop_stack(backpatch_stack);
                                        popped = push_stack(popped, popped_node);
                                    }

                                    // If found a CASE_START flag, backpatch the previous case
                                    if (backpatch_stack->top > -1) {
                                        struct list_node* case_flag = pop_stack(backpatch_stack);
                                        struct list_node* jump_to_backpatch = pop_stack(popped);
                                        backpatch(jump_to_backpatch, generated_commands->size);
                                    }

                                    // Push all the popped elements back to the stack
                                    while (popped != NULL && popped->top > -1) {
                                        struct list_node* popped_node = pop_stack(popped);
                                        backpatch_stack = push_stack(backpatch_stack, popped_node);
                                    }

                                    // Place a flag to mark the start of the case, for backpatching
                                    char case_start_flag[COMMAND_LENGTH];
                                    sprintf(case_start_flag, "CASE_START");
                                    struct list_node* case_flag = new_list_node(case_start_flag);
                                    backpatch_stack = push_stack(backpatch_stack, case_flag);

                                    // Add the jump command to next case
                                    char jump_command[COMMAND_LENGTH];
                                    sprintf(jump_command, "JMPZ %%d %s", temp_name);
                                    append_value(generated_commands, jump_command);
                                    backpatch_stack = push_stack(backpatch_stack, generated_commands->tail);
                                    break;
                                }
                            }
                        } else {
                            fprintf(stderr, "line %d: Case value is not an integer!\n", yylineno);
                            error_flag = true;
                        }
                    }
                    stmtlist
                |   /* empty */
                ;

break_stmt      :   BREAK ';'
                    {
                        bool case_context = false;
                        for (int i = backpatch_stack->top; i > -1; i--) {
                            if (strcmp(backpatch_stack->stack_arr[i]->value, "SWITCH_START") == 0) {
                                case_context = false;
                                break;
                            }
                            if (strcmp(backpatch_stack->stack_arr[i]->value, "CASE_START") == 0) {
                                case_context = true;
                                break;
                            }
                            if (strcmp(backpatch_stack->stack_arr[i]->value, "WHILE_START") == 0) {
                                case_context = true;
                                break;
                            }
                        }

                        if (case_context) {
                            struct list_node* break_command = new_list_node("JMP %d");
                            append_value(generated_commands, break_command->value);
                            backpatch_stack = push_stack(backpatch_stack, generated_commands->tail);
                        } else {
                            fprintf(stderr, "line %d: Break statement not in case or while context!\n", yylineno);
                            error_flag = true;
                        }
                    }
                ;

stmt_block      :   '{' stmtlist '}'
                ;

stmtlist        :   stmtlist stmt
                |   /* empty */
                ;

boolexpr        :   boolexpr OR boolterm
                    {
                        struct dict_item* a = lookup(symbols_table, $1);
                        struct dict_item* b = lookup(symbols_table, $3);
                        if (a != NULL && b != NULL) {
                            // We need a temporary variable to store the value of 0 - define if not already set
                            zero = get_zero();

                            sprintf($$, "T%d", temp_count++);

                            char add_command[COMMAND_LENGTH];
                            bool is_const = a->is_const && b->is_const;

                            // add the boolean values, if the addition result > 0 then the result is true
                            float res = is_const ? a->val + b->val : NO_VAL;
                            sprintf(add_command, "IADD %s %s %s", $$, $1, $3);
                            struct dict_item* add_result = install(symbols_table, $$, INT_CODE, (int)res, is_const);
                            append_value(generated_commands, add_command);
                            sprintf($$, "T%d", temp_count++);

                            char command[COMMAND_LENGTH];

                            res = is_const ? add_result->val > 0 : NO_VAL;
                            sprintf(command, "IGRT %s %s %s", $$, add_result->name, zero->name);
                            install(symbols_table, $$, INT_CODE, (int)res, is_const);
                            append_value(generated_commands, command);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                error_flag = true;
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                error_flag = true;
                                strcpy($$, $1);
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
                            sprintf(command, "IMLT %s %s %s", $$, $1, $3);
                            install(symbols_table, $$, INT_CODE, (int)res, is_const);
                            append_value(generated_commands, command);
                        } else {
                            if (a == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $1);
                                error_flag = true;
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                error_flag = true;
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
                            // We need a temporary variable to store the value of 1 - define if not already set
                            one = get_one();

                            sprintf($$, "T%d", temp_count++);
                            char command[COMMAND_LENGTH];

                            // Using (1.0 - var->val) to invert the boolean value of var
                            float res = var->is_const ? one->val - var->val : NO_VAL;

                            install(symbols_table, $$, INT_CODE, res, var->is_const);
                            sprintf(command, "ISUB %s %s %s", $$, one->name, $3);
                            append_value(generated_commands, command);
                        } else {
                            fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                            error_flag = true;
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
                                    sprintf(cast_command, "ITOR %s %s", $$, b->name);
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
                                error_flag = true;
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                error_flag = true;
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
                                error_flag = true;
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                error_flag = true;
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
                                error_flag = true;
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
                                error_flag = true;
                                strcpy($$, $3);
                            }
                            if (b == NULL) {
                                fprintf(stderr, "line %d: The variable %s was not declared!\n", yylineno, $3);
                                error_flag = true;
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
                            error_flag = true;
                            strcpy($$, $3);
                        } else {
                            char command[COMMAND_LENGTH];
                            if (var->type == INT_CODE && $1 == CASTF) {
                                sprintf($$, "T%d", temp_count++);
                                sprintf(command, "ITOR %s %s", $$, $3);
                                append_value(generated_commands, command);
                                install(symbols_table, $$, FLOAT_CODE, var->val, false);
                            } else if (var->type == FLOAT_CODE && $1 == CASTI) {
                                sprintf($$, "T%d", temp_count++);
                                sprintf(command, "RTOI %s %s", $$, $3);
                                append_value(generated_commands, command);
                                install(symbols_table, $$, INT_CODE, (int)var->val, false);
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

void yyerror (char* output_file, const char* s) {
    fprintf (stderr, "line %d: %s\n", yylineno, s);
    error_flag = true;
}

