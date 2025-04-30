// This is an implementation of a dictionary using a hash table
// Implementation taken from:
// https://stackoverflow.com/questions/4384359/quick-way-to-implement-dictionary-in-c - Credit

#include "dict.h"

unsigned hash(char* s) {
    unsigned hashval;
    for (hashval = 0; *s != '\0'; s++)
      hashval = *s + 31 * hashval;
    return hashval % HASHSIZE;
}

struct dict_item* lookup(dict d, char* s) {
    struct dict_item* di;
    for (di = d[hash(s)]; di != NULL; di = di->next)
        if (strcmp(s, di->name) == 0)
          return di;
    return NULL;
}

struct dict_item* install(dict d, char* name, int type, float val, bool is_const) {
    struct dict_item* di;
    unsigned hashval;

    if ((di = lookup(d, name)) == NULL) {
        // If not found, create a new item
        di = (struct dict_item *) malloc(sizeof(*di));

        // TODO: Should probably check for malloc failure on every malloc - go over the code and add checks!
        // Check that malloc & strdup were successful
        if (di == NULL || (di->name = strdup(name)) == NULL)
            fprintf(stderr, "Out of memory\n"), exit(1);

        hashval = hash(name);

        // This item will be the first in the chain, so 'next' should be the start of current chain
        di->next = d[hashval];

        // Set the item's properties
        di->type = type;
        di->val = val;
        di->is_const = is_const;

        // Insert the new item at the start of the chain
        d[hashval] = di;
    } else {
        // Item found, update its properties
        di->type = type;
        di->val = val;
        di->is_const = is_const;
    }
    return di;
}

void print_dict(dict d) {
    for (int i = 0; i < HASHSIZE; i++) {
        struct dict_item *di = d[i];
        while (di != NULL) {
            printf("Key: %s, Type: %d, Value: %f\n", di->name, di->type, di->val);
            di = di->next;
        }
    }
}

void free_dict(dict d) {
    for (int i = 0; i < HASHSIZE; i++) {
        struct dict_item *di = d[i];
        while (di != NULL) {
            struct dict_item *temp = di;
            di = di->next;
            free(temp->name);
            free(temp);
        }
    }
}

