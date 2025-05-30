#include "linked_list.h"

// This is a classic implementation of a linked list in C

struct linked_list* new_linked_list(const char* value) {
    struct linked_list* list = (struct linked_list*)malloc(sizeof(struct linked_list));
    list->head = new_list_node(value);
    list->tail = list->head;
    list->size = 1;
    return list;
}

struct list_node* new_list_node(const char* value) {
    struct list_node* node = (struct list_node*)malloc(sizeof(struct list_node));
    node->value = strdup(value);
    node->next = NULL;
    return node;
}

struct linked_list* append_value(struct linked_list* list, const char* value) {
    if (list == NULL) {
        return new_linked_list(value);
    }

    list->tail->next = new_list_node(value);
    list->tail = list->tail->next;
    list->size++;
    return list;
}

struct linked_list* append_linked_list(struct linked_list* list, struct linked_list* list_to_append) {
    if (list == NULL) {
        return list_to_append;
    }
    if (list_to_append == NULL) {
        return list;
    }

    list->tail->next = list_to_append->head;
    list->tail = list_to_append->tail;
    list->size += list_to_append->size;
    free(list_to_append);
    return list;
}

void free_linked_list(struct linked_list* list) {
    if (list == NULL) return;
    free_list_nodes(list->head);
    free(list);
}

void free_list_nodes(struct list_node* node) {
    if (node == NULL) return;
    struct list_node* next = node->next;

    free(node->value);
    free(node);
    free_list_nodes(next);
}

void print_linked_list(struct linked_list* list) {
    // printf("Printing linked list:\n");
    struct list_node* current = list->head;
    int i = 1;
    while (current != NULL) {
        printf("%d: %s\n", i++, current->value);
        current = current->next;
    }
}

