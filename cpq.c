#include <stdio.h>

int main (int argc, char **argv) {
    extern FILE *yyin;
    if (argc != 2) {
       fprintf (stderr, "Usage: %s <input-file-name>\n", argv[0]);
       return 1;
    }

    yyin = fopen (argv [1], "r");
    if (yyin == NULL) {
         fprintf (stderr, "failed to open %s\n", argv[1]);
         return 2;
    }

    fprintf (stdout, "Managed to read the file!\n");

    int token;
    while ((token = yylex()) != 0) {
        fprintf (stdout, "Token: %d\n", token);
    }

    return 0;
}
