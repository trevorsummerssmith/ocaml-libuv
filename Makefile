# This makefile is jank. We will redo.
all:
	corebuild -Is src examples/cat.native -pkg ctypes.stubs -pkg ctypes.foreign -lflags -cclib,-luv -tag debug -cflag -g -lflags -cclib,-v

tests:
	corebuild -Is src test/test_runner.native -pkg ounit -pkg ctypes.foreign -lflags -cclib,-luv && ./test_runner.native

clean:
	rm -rf _build; rm -f *.native
	# ocamlbuild -clean

# libuv_stubs.o gcc -c libuv_stubs.c -I ~/.opam/4.02.0/lib/ocaml -I ~/.opam/4.02.0/lib/
# final linking:
# ocamlfind ocamlopt -cclib -luv -cclib -v -linkpkg -g -thread -syntax camlp4o -package ctypes.foreign -package ctypes.stubs -package bin_prot.syntax -package sexplib.syntax,comparelib.syntax,fieldslib.syntax,variantslib.syntax -package core src/libuv_bindings.cmx src/libuv_generated.cmx src/refcount.cmx src/uv.cmx src/libuv_stubs.o examples/cat.cmx -o examples/cat.native
