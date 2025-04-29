#ifndef LINKED_LIST_H
#define LINKED_LIST_H

struct list_node* new_list(const char* value);
struct list_node* append_node(struct list_node* list, const char* value);

#endif // LINKED_LIST_H 