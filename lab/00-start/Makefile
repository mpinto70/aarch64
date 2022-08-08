
PROGS = \
	00-hello-world.exe \
	01-hello-world.exe \
	02-cmd-args.exe \
	03-greater-of-two.exe \
	04-bubble-sort.exe \
	05-quick-sort.exe \
	06-random.exe \
	07-seed.exe \
	08-memory.exe \

CPROGS = \
	test-sort.exe \

all: $(PROGS) $(CPROGS)

.cpp.o:
	g++ -c $< -std=c++17 -o $@

.s.o:
	cpp -E $< > $<.tmp.s
	as -o $@ $<.tmp.s
	rm -f $<.tmp.s

clean:
	rm -vf *.o \
		$(PROGS) \
		$(CPROGS)

$(PROGS): %.exe: %.o utils.o sort.o
	ld -o $@ $< utils.o sort.o

$(CPROGS): %.exe: %.o utils.o sort.o
	g++ -o $@ $< utils.o sort.o
