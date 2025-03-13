CC = gcc
OBJS = cpq.o lex.yy.c cpq.tab.h cpq.tab.c
EXEC = cpq
COMP_FLAG = -Wno-implicit-function-declaration

$(EXEC) : $(OBJS)
	$(CC) $(COMP_FLAG) $(OBJS) -o $(EXEC)

cpq.o : cpq.c
	$(CC) -c $(COMP_FLAG) cpq.c

lex.yy.c : cpq.lex
	flex cpq.lex

cpq.tab.h cpq.tab.c: cpq.y
	bison -d cpq.y

clean:
	rm -f $(OBJS) $(EXEC)
