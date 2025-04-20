#ifndef TYPES_H
#define TYPES_H

#define EQ                      10
#define NEQ                     11
#define LT                      12
#define GT                      13
#define GTE                     14
#define LTE                     15
#define ADD                     16
#define SUB                     17
#define MUL                     18
#define DIV                     19
#define CASTI                   20
#define CASTF                   21
#define INT_CODE                22
#define FLOAT_CODE              23

typedef struct nlist { /* table entry: */
    struct nlist *next; /* next entry in chain */
    char *name; /* defined name */
    float val; /* replacement text */
    int type;
} nlist;

#endif // TYPES_H 