/* Generate a list of constant definitions from c to ocaml.
 *
 * Heavily indebted to
 * https://github.com/dbuenzli/tsdl/blob/master/support/consts_stub.c .
 */


#include <caml/mlvalues.h>
#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <uv.h>

void let (FILE *fd, const char *symb) {
    int i;
    fprintf (fd, "let ");
    for (i = 0; i < strlen(symb); i++) {
        fprintf (fd, "%c", tolower (symb[i]));
    }
}

void str_v (FILE *fd, char *symb, const char *value) {
    let (fd, symb); fprintf (fd, " = \"%s\"\n", value);
}

void int_v (FILE *fd, char *symb, int value) {
    let (fd, symb); fprintf (fd, " = %d\n", value);
}

void int_vx (FILE *fd, char *symb, int value) {
    let (fd, symb); fprintf (fd, " = 0x%X\n", value);
}

void int32_v (FILE *fd, char *symb, int32_t value) {
    let (fd, symb); fprintf (fd, " = 0x%Xl\n", value);
}

void consts (FILE *fd) {

    #define int_v(e) int_v(fd, "" # e, (int)e)
    #define int_vx(e) int_vx(fd, "" # e, (int)e)
    #define int32_v(e) int32_v(fd, "" # e, (int32_t)e)
    #define str_v(e) str_v(fd, "" # e, (const char *)e)

    /* Error codes */
    int_v(UV_EOF);

}

CAMLprim value output_consts (value fname) {
    char *outf = String_val (fname);
    FILE *fd;
    if (strlen(outf) == 0) {
        fd = stdout;
    } else {
        fd = fopen (outf, "w");
        if (!fd) {
            perror(outf); exit (1);
        }
    }
    consts(fd);
    fflush(fd);
    if (fd != stdout) {
        fclose (fd);
    }
    return Val_unit;
}
