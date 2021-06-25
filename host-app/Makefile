CC=$(CROSS_COMPILE)g++
SRCS=$(wildcard src/*.c)
OBJS=$(patsubst %.c,%.o,$(SRCS))
CFLAGS=-Wall -Werror -static -Isrc --std=c++11
LDFLAGS=
LDLIBS=
OUT=host-app

$(OUT): $(OBJS)
	$(CC) -o $@ $^ $(CFLAGS) $(LDFLAGS) $(LDLIBS)

clean:
	rm -rf $(OUT) $(OBJS)

.PHONY: clean
