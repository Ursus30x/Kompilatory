CC = gcc
LEX = flex
YACC = bison
YFLAGS = -Wcounterexamples -d
CFLAGS = -Wall -Wextra -DYYDEBUG=1
PLANG = simula

% : %.tab.o %.o
	$(CC) $(CFLAGS) $< $*.o -o $@

%.tab.c %.tab.h: %.y
	$(YACC) $(YFLAGS) $<

%.c: %.l %.tab.h
	$(LEX) -t $< > $@

$(PLANG): $(PLANG).y $(PLANG).l
