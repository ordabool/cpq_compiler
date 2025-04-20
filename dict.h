#ifndef DICT_H
#define DICT_H

unsigned hash(char *s);
struct nlist *lookup(char *s);
struct nlist *install(char *name, int type, float val);

#endif // DICT_H 