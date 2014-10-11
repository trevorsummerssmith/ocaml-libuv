# This makefile is jank. We will redo.
.PHONY: all
all: cat tcp

tcp:
	corebuild -Is src examples/tcp_echo_server.native -pkg ctypes.stubs -pkg ctypes.foreign -lflags -cclib,-luv -tag debug -cflag -g -cflag

cat:
	corebuild -Is src examples/cat.native -pkg ctypes.stubs -pkg ctypes.foreign -lflags -cclib,-luv -tag debug -cflag -g -cflag

tests:
	corebuild -Is src test/test_runner.native -pkg ounit -pkg ctypes.foreign -lflags -cclib,-luv && ./test_runner.native

clean:
	ocamlbuild -clean
