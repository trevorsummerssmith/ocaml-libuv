all:
	corebuild cat.native -pkg ctypes.foreign -lflags -cclib,-luv
