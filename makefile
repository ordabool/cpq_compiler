CC = gcc
OBJS = cpq.o linked_list.o dict.o lex.yy.c cpq.tab.h cpq.tab.c
EXEC = cpq
COMP_FLAG = -Wno-implicit-function-declaration -Wno-int-conversion

$(EXEC) : $(OBJS)
	@$(CC) $(COMP_FLAG) $(OBJS) -o $(EXEC)

# Prevent default make behavior (overwrites cpq.c)
%.c: %.y
%.c: %.l

cpq.o : cpq.c
	@$(CC) -c $(COMP_FLAG) cpq.c

dict.o : dict.c
	@$(CC) -c $(COMP_FLAG) dict.c

linked_list.o : linked_list.c
	@$(CC) -c $(COMP_FLAG) linked_list.c

lex.yy.c : cpq.lex
	@flex cpq.lex

cpq.tab.h cpq.tab.c: cpq.y
	@bison -d cpq.y

clean:
	@rm -f $(OBJS) $(EXEC)
