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

void string_v (FILE *fd, char *symb, const char *value) {
    let (fd, symb); fprintf (fd, " = \"%s\"\n", value);
}

void integer_v (FILE *fd, char *symb, int value) {
    let (fd, symb); fprintf (fd, " = %d\n", value);
}

void integer_vx (FILE *fd, char *symb, int value) {
    let (fd, symb); fprintf (fd, " = 0x%X\n", value);
}

void integer32_v (FILE *fd, char *symb, int32_t value) {
    let (fd, symb); fprintf (fd, " = 0x%Xl\n", value);
}

#define int_v(e) integer_v(fd, "" # e, (int)e)
#define int_vx(e) integer_vx(fd, "" # e, (int)e)
#define int32_v(e) integer32_v(fd, "" # e, (int32_t)e)
#define str_v(e) string_v(fd, "" # e, (const char *)e)
#define size_of(e) integer_v(fd, "size_of_" # e, (int)(sizeof(e)))

void make_error_codes(FILE *fd) {
    /* Error codes.

       We need to:
         1) generate a set of constructors from the error names
	 2) generate a function for converting from the integer error
	    and the enum.
	 3) (We don't really need this but people will probably want it)
	 Generate ocaml error type -> int.
	 4) Generate error to string message

       uv.h exposes UV_ERRNO_MAP which is basically a map function on
       a set of pairs that are name without UV_ prefix, and string.
       We'll take this list and get the names of the enums it creates.
     */
    // 1) Generate ocaml datatype
    fprintf(fd, "type error =\n");
#define XX(code, _)   fprintf(fd, "  | UV_" #code "\n");
    UV_ERRNO_MAP(XX)
#undef XX

    // 2) Convert from int to error type
    fprintf(fd, "let int_to_error = function\n");
#define XX(code, _) fprintf(fd, "  | %d -> UV_" # code "\n", UV_ ## code);
    UV_ERRNO_MAP(XX)
#undef XX
    fprintf(fd, "  | _ -> failwith \"Unknown error code. "
	    "This should not happen. This means the version "
	    "of libuv is different than the version used to compile "
	    "ocaml-libuv.\"\n");

    // 3) Convert from error type to int
    fprintf(fd, "let error_to_int = function\n");
#define XX(code, _) fprintf(fd, "  | UV_" #code " -> %d\n", UV_ ## code);
    UV_ERRNO_MAP(XX)
#undef XX

    // 4) Generate error to string. (we could use uv_strerror but then we'd
    // have to cast back to an int, etc. Easier to just define it here in ocaml)
    fprintf(fd, "let error_to_string = function\n");
#define XX(code, msg) fprintf(fd, "  | UV_" #code " -> \"%s\"\n", msg);
    UV_ERRNO_MAP(XX)
#undef XX

}

void consts (FILE *fd) {

    /* Size of structs (because their sizes are platform dependent) */
    size_of(uv_fs_t);
    size_of(uv_connect_t);

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
    make_error_codes(fd);
    fflush(fd);
    if (fd != stdout) {
        fclose (fd);
    }
    return Val_unit;
}
