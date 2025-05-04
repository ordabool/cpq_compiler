#ifndef STACK_H
#define STACK_H

#include <stdio.h>
#include <stdlib.h>
#include "linked_list.h"

#define STACK_SIZE 50

// The stack is implemented as an array of pointers to list_node
typedef list_node* stack_arr[STACK_SIZE];

// The stack structure contains the array and an integer to track the top of the stack
typedef struct stack {
    stack_arr stack_arr;
    int top;
} stack;

// Push a node onto the stack
struct stack* push_stack(stack* s, list_node* n);

// Pop a node from the stack
struct list_node* pop_stack(stack* s);

// Free the stack
void free_stack(stack* s);

// Print the contents of the stack
void print_stack(stack* s);

#endif // STACK_H
