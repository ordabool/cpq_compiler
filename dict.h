#ifndef DICT_H
#define DICT_H

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdbool.h>

// The dictionary item has 'next' for chaining on hash collisions
typedef struct dict_item {
    struct dict_item* next;
    char* name;
    float val;
    int type;
    bool is_const;
} dict_item;

#define HASHSIZE 101
typedef dict_item* dict[HASHSIZE];


unsigned hash(char *s);
struct dict_item* lookup(dict d, char *s);
struct dict_item* install(dict d, char* name, int type, float val, bool is_const);
void print_dict(dict d);
void free_dict(dict d);

#endif // DICT_H
