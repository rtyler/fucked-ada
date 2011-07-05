
GNATMAKE=gnatmake
CFLAGS=-gnat05 -O3

fucked:
	$(GNATMAKE) $(CFLAGS) fucked.adb

clean:
	rm -f fucked *.o *.ali

.PHONY: fucked
