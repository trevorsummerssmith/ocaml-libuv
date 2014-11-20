# This makefile is jank. We will redo.
.PHONY: all
all: cat tcp

tcp:
	ocamlbuild -Is src examples/tcp_echo_server.native -lflags -cclib,-luv -tag debug -cflag -g

cat:
	ocamlbuild -Is src examples/cat.native -lflags -cclib,-luv -tag debug -cflag -g

tests:
	ocamlbuild -Is src test/test_runner.native -lflags -cclib,-luv && ./test_runner.native

clean:
	ocamlbuild -clean
