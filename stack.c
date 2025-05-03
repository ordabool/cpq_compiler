// Implementation taken from:
// https://www.digitalocean.com/community/tutorials/stack-in-c

#include "stack.h"

struct stack* push_stack(stack* s, list_node* n) {
    if (s == NULL) {
        s = (struct stack*)malloc(sizeof(struct stack));
        s->top = -1;
    }

    if (s->top == STACK_SIZE - 1) {
        fprintf(stderr, "Stack Overflow!\n");
        return NULL;
    } else {
        s->top++;
        s->stack_arr[s->top] = n;
    }
    return s;
}

struct list_node* pop_stack(stack* s) {
    if (s == NULL || s->top == -1) {
        fprintf(stderr, "Stack Underflow!\n");
        return NULL;
    } else{
        s->top--;
        return s->stack_arr[s->top + 1];
    }
}

void free_stack(stack* s) {
    if (s == NULL) return;
    free(s);
}

