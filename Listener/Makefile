CC=gcc
#CFLAGS=-I.
#LIBS=-lpthread
#DEPS=$(wildcard *.h)
#SRC=CStates.cpp  Config.cpp  Dispatcher.cpp  Worker.cpp  main.cpp  stats.cpp  stdafx.cpp

all:
	$(CC) -o gcc -o listener listener.c getpids.c -lpthread

clean:
	rm -f ./listener
