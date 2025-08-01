CC=g++
CXXFLAGS=-Wall -Wextra -O2 -std=c++11 -I.
LDFLAGS=
LIBS=-lpthread
DEPS=$(wildcard *.h)
SRC=listener.cpp getpids.c

all: $(DEPS) listener

listener: $(SRC)
	$(CC) $(CXXFLAGS) -o $@ $^ $(LDFLAGS) $(LIBS)

clean:
	rm -f ./listener

.PHONY: all clean
