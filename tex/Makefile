#
# @(#) Makefile - makefile for Rail package
#
# 07-Feb-1991 L. Rooijakkers	added 'tar' target
# 12-Feb-1991 L. Rooijakkers	added 'patch' target
# 14-Jan-1997 K. Barthelmann	minor modifications
# 28-Oct-1997 K. Barthelmann	minor modifications
#

BINDIR=$(HOME)/bin
TEXDIR=$(HOME)/tex
MANDIR=$(HOME)/man
MANSUFFIX=l

OBJS=rail.o gram.o lex.o

CC=gcc
CFLAGS=-DYYDEBUG -O
YACC=bison -y
#YACC=byacc
LEX=flex

all: rail 

install: rail rail.sty rail.man
	cp rail $(BINDIR)
	cp rail.sty $(TEXDIR)
	cp rail.man $(MANDIR)/man$(MANSUFFIX)/rail.$(MANSUFFIX)

clean:
	-rm -f $(OBJS) rail gram.[ch] lex.c y.tab.[ch] y.output a.out core PATCH
	-rm -f *.log *.aux *.rai *.rao *.dvi rail.txt SHAR.* TAR MANIFEST.BAK

lint: rail.c gram.c lex.c gram.h 
	lint rail.c gram.c lex.c
	
shar:
	makekit -m -n SHAR.

tar:
	tar cvf TAR `sed -n '3,$$s/^[ 	]*\([^ 	]*\).*$$/\1/p' MANIFEST`

patch:
	diff -bc old . | sed '/^diff/d' >PATCH

doc:	rail.dvi rail.txt

$(OBJS): rail.h

rail.o lex.o: gram.h

rail.o: patchlevel.h

gram.c gram.h: y.tab.c y.tab.h
	cmp -s gram.c y.tab.c || cp y.tab.c gram.c
	cmp -s gram.h y.tab.h || cp y.tab.h gram.h

y.tab.c y.tab.h y.output: gram.y
	$(YACC) $(YFLAGS) -dv gram.y

rail: $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o rail

rail.rai: rail.tex
	latex rail

rail.rao: rail rail.rai
	./rail rail

rail.dvi: rail.rao rail.tex
	latex rail

rail.txt: rail.man
	nroff -man rail.man >rail.txt
