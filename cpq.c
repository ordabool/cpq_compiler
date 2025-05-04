#include <stdio.h>
#include <string.h>

int main (int argc, char **argv) {
    extern FILE *yyin;

    // Validate the file argument
    if (argc != 2) {
       fprintf (stderr, "Usage: %s <input-file-name>\n", argv[0]);
       return 1;
    }

    // Check that the file type is .ou
    char *file_extension = strrchr(argv[1], '.');
    if (file_extension == NULL || strcmp(file_extension, ".ou") != 0) {
        fprintf(stderr, "Error: Input file must have .ou extension\n");
        return 2;
    }

    // Check that the file exists and is readable
    yyin = fopen (argv [1], "r");
    if (yyin == NULL) {
         fprintf (stderr, "failed to open %s\n", argv[1]);
         return 3;
    }

    // Set output_file to the same name as input_file but with .out extension
    char output_file[256];
    strncpy(output_file, argv[1], sizeof(output_file) - 1);
    output_file[sizeof(output_file) - 1] = '\0'; // Ensure null-termination
    size_t len = strlen(output_file);
    if (len >= 3) {
        output_file[len - 3] = '\0'; // Remove the .ou
    }
    strncat(output_file, ".qud", sizeof(output_file) - strlen(output_file) - 1);

    // Parse the input file and close the input file
    yyparse(output_file);
    fclose (yyin);

    // Signature line
    fprintf (stderr, "Created by Or Dabool");
    
    return 0;
}
