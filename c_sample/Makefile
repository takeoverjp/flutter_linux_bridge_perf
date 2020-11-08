.PHONY: all clean

all: memset
clean:
	rm -f memset *~

memset: memset.c
	gcc -W -Wall -Werror -O3 -static -o $@ $^
