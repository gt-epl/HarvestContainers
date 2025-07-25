CC=gcc
CFLAGS=-Wall -Wextra -O2 -I.
LIBS=-lpthread
DEPS=$(wildcard *.h)
SRC=listener.c getpids.c

all: $(DEPS) listener

listener: $(SRC)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

clean:
	rm -f ./listener

.PHONY: all clean
