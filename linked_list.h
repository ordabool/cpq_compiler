#ifndef LINKED_LIST_H
#define LINKED_LIST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// A list node contains a string value and a pointer to the next node
typedef struct list_node {
    char* value;
    struct list_node* next;
} list_node;

// The linked list contains pointers to the head and tail nodes, and an integer for the size
typedef struct linked_list {
    struct list_node* head;
    struct list_node* tail;
    int size;
} linked_list;


// Create a new linked list with a given value for the head node
struct linked_list* new_linked_list(const char* value);

// Create a new node with a given value
struct list_node* new_list_node(const char* value);

// Append a new node with a given value to the end of the linked list
struct linked_list* append_value(struct linked_list* list, const char* value);

// Append an existing list to the end of another linked list
struct linked_list* append_linked_list(struct linked_list* list, struct linked_list* list_to_append);

// Free the memory allocated for the linked list
void free_linked_list(struct linked_list* list);

// Free the memory allocated for the nodes in the linked list
void free_list_nodes(struct list_node* node);

// Print the contents of the linked list
void print_linked_list(struct linked_list* list);

#endif // LINKED_LIST_H
