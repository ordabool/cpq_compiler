CC = gcc
OBJS = cpq.o lex.yy.c
EXEC = cpq
COMP_FLAG = -std=c99

$(EXEC) : $(OBJS)
	$(CC) $(COMP_FLAG) $(OBJS) -o $@

cpq.o : cpq.c
	$(CC) -c $(COMP_FLAG) $*.c

lex.yy.c : cpq.lex
	flex cpq.lex

clean:
	rm -f $(OBJS) $(EXEC)