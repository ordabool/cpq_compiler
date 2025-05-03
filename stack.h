#ifndef STACK_H
#define STACK_H

#include <stdio.h>
#include <stdlib.h>
#include "linked_list.h"

#define STACK_SIZE 50
typedef list_node* stack_arr[STACK_SIZE];
typedef struct stack {
    stack_arr stack_arr;
    int top;
} stack;

struct stack* push_stack(stack* s, list_node* n);
struct list_node* pop_stack(stack* s);
void free_stack(stack* s);
void print_stack(stack* s);

#endif // STACK_H
