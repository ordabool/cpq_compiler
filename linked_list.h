#ifndef LINKED_LIST_H
#define LINKED_LIST_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct list_node {
    char* value;
    struct list_node* next;
} list_node;

typedef struct linked_list {
    struct list_node* head;
    struct list_node* tail;
    int size;
} linked_list;


struct linked_list* new_linked_list(const char* value);
struct list_node* new_list_node(const char* value);
struct linked_list* append_value(struct linked_list* list, const char* value);
struct linked_list* append_linked_list(struct linked_list* list, struct linked_list* list_to_append);
void free_linked_list(struct linked_list* list);
void free_list_nodes(struct list_node* node);
void print_linked_list(struct linked_list* list);

#endif // LINKED_LIST_H
