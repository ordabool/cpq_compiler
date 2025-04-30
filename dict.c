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

struct dict_item* lookup(dict d, char *s) {
    struct dict_item *np;
    for (np = d[hash(s)]; np != NULL; np = np->next)
        if (strcmp(s, np->name) == 0)
          return np;
    return NULL;
}

struct dict_item* install(dict d, char* name, int type, float val, bool is_const) {
    struct dict_item *np;
    unsigned hashval;
    if ((np = lookup(d, name)) == NULL) {
        np = (struct dict_item *) malloc(sizeof(*np));
        if (np == NULL || (np->name = strdup(name)) == NULL)
          return NULL;
        hashval = hash(name);
        np->next = d[hashval];
        np->type = type;
        np->val = val;
        d[hashval] = np;
    } else {
        np->type = type;
        np->val = val;
    }
    return np;
}

void print_dict(dict d) {
    for (int i = 0; i < HASHSIZE; i++) {
        struct dict_item *np = d[i];
        while (np != NULL) {
            printf("Key: %s, Type: %d, Value: %f\n", np->name, np->type, np->val);
            np = np->next;
        }
    }
}

void free_dict(dict d) {
    for (int i = 0; i < HASHSIZE; i++) {
        struct dict_item *np = d[i];
        while (np != NULL) {
            struct dict_item *temp = np;
            np = np->next;
            free(temp->name);
            free(temp);
        }
    }
}

