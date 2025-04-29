#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "linked_list.h"

struct linked_list* new_linked_list(const char* value) {
    printf("Creating new linked list\n");
    struct linked_list* list = (struct linked_list*)malloc(sizeof(struct linked_list));
    list->head = new_list_node(value);
    list->tail = list->head;
    return list;
}

struct list_node* new_list_node(const char* value) {
    printf("Creating new node for value: %s\n", value);
    struct list_node* node = (struct list_node*)malloc(sizeof(struct list_node));
    node->value = strdup(value);
    node->next = NULL;
    return node;
}

struct linked_list* append_value(struct linked_list* list, const char* value) {
    printf("Appending value: %s\n", value);
    if (list == NULL) {
        return new_linked_list(value);
    }

    list->tail->next = new_list_node(value);
    list->tail = list->tail->next;
    return list;
}

void free_linked_list(struct linked_list* list) {
    printf("Freeing linked list\n");
    if (list == NULL) return;
    free_list_nodes(list->head);
    free(list);
}

void free_list_nodes(struct list_node* node) {
    if (node == NULL) return;
    printf("Freeing node with value: %s\n", node->value);
    struct list_node* next = node->next;

    free(node->value);
    free(node);
    free_list_nodes(next);
}
