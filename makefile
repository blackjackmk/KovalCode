kompilator: gramatyka.tab.o lex.yy.o zmienne.o stack.o
	gcc -o kompilator lex.yy.o gramatyka.tab.o zmienne.o stack.o -lfl
lex.yy.o: lex.yy.c
	gcc -c lex.yy.c
lex.yy.c: leksyka.l
	lex leksyka.l
gramatyka.tab.o: gramatyka.tab.c
	gcc -c gramatyka.tab.c
gramatyka.tab.c: gramatyka.y
	bison -d gramatyka.y
zmienne.o: zmienne.c zmienne.h
	gcc -c zmienne.c
stack.o: stack.c stack.h
	gcc -c stack.c
clean:
	rm -f *.o
	echo Clean done!
