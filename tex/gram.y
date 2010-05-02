/* gram.y - yacc grammar for rail program */

%{

#include <stdio.h>

#include "rail.h"

char optchar;

%}

/* identifier */

%token <id> IDENTIFIER

/* number */

%token <num> NUMBER

/* [annotation] */

%token <text> ANNOT

/* \rail@i \rail@p \rail@t \\ */

%token RAILI RAILP RAILT RAILCR

/* TeX control sequence */

%token CS

/* 'c' "string" */

%token <text> STRING

%type <rule> rule rules

%type <body> body body0 body1 body2e body2 body3 body4e body4 empty

%type <text> annot

%start rails

%%

rails	: rails rail
	| rail
	;

rail	: RAILI raili
	| RAILP railp
	| RAILT railt
	| error
	;

railp	:
	  '{'
		{
			fprintf(outf,"\\rail@p {");
			copy=1;
			optchar = '-';
		}
	  options '}'
		{
			fprintf(outf,"\n");
			copy=0;
		}
	;

options	: /*empty*/
	| options '-'
		{ optchar = '-'; }
	| options '+'
		{ optchar = '+'; }
	| options IDENTIFIER
		{
			if(setopt(optchar,$2->name)==0)
				error("unknown option",(char *)NULL);

			if($2->kind==UNKNOWN)
				delete($2);
		}
	;
		
railt	: '{' IDENTIFIER '}' 
		{
			if($2->kind==UNKNOWN || $2->kind==TOKEN)
				$2->kind=TERM;
			else
				redef($2);

			fprintf(outf,"\\rail@t {%s}\n",$2->name);
		}
	;

raili	: '{' NUMBER '}'
		{
			fprintf(outf,"\\rail@i {%d}",$2);
			copy=1;
		}
	  '{' rules '}'
		{	copy=0;
			fprintf(outf,"\n");
			fprintf(outf,"\\rail@o {%d}{\n",$2);
			outrule($6);	/* embedded action is $4 */
			freerule($6);
			fprintf(outf,"}\n");
		}
	;

rules	: rules ';' rule
		{ $$=addrule($1,$3); }
	| rules ';'
		{ $$=$1; }
	| rule
	| error
		{ $$=NULL; }
	;
	
rule	: IDENTIFIER ':'
		{ errorid=$1; }
          body
		{
			if($1->kind==UNKNOWN || $1->kind==TOKEN)
				$1->kind=NTERM;
			else
				redef($1);

		 	$$=newrule($1,$4);	/* embedded action is $3 */

			errorid=NULL;
		}
	| body
		{
			anonymous++;

			$$=newrule((IDTYPE *)NULL,$1);
		}
	;

body	: body0 
		{ $$=$1; $$->done=1; }
	;

body0	: body0 '|' ANNOT body1
		{
			$$=newbody(ANNOTE,NULLBODY,NULLBODY);
			$$->text=$3;
			$$=addbody(CAT,$$,$4);
			$$=addbody(BAR,$1,$$);
		}
	| body0 '|' body1
		{ $$=addbody(BAR,$1,$3); }
	| ANNOT body1
		{
			$$=newbody(ANNOTE,NULLBODY,NULLBODY);
			$$->text=$1;
			$$=addbody(CAT,$$,$2);
		}
	| body1
	;

body1	: body2 '*' body4e
		{
			if(altstar && isemptybody($3)) {
				$$=newbody(EMPTY,NULLBODY,NULLBODY);
				$$=addbody(PLUS,$$,revbody($1));
			} else {
				$$=newbody(EMPTY,NULLBODY,NULLBODY);
				$$=addbody(BAR,$$,addbody(PLUS,$1,revbody($3)));
			}
		}
	| body2 '+' body4e
		{ $$=newbody(PLUS,$1,revbody($3)); }
	| body2e
	;

body2e	: body2 | empty ;

body2	: body2 body3
		{ $$=addbody(CAT,$1,$2); }
	| body3
	;

body3	: body4 '?'
		{ $$=addbody(BAR,newbody(EMPTY,NULLBODY,NULLBODY),$1); }
	| body4
	;

body4e	: body4 | empty ;

body4	: '(' body0 ')'
		{ $$=$2; $$->done=1; }
	| STRING annot
		{
			$$=newbody(STRNG,NULLBODY,NULLBODY);
			$$->annot=$2;
			$$->text=$1;
		}
	| IDENTIFIER annot
		{
			if($1->kind==UNKNOWN)
				$1->kind=TOKEN;

			$$=newbody(IDENT,NULLBODY,NULLBODY);
			$$->annot=$2;
			$$->id=$1;
		}
	| RAILCR
		{ $$=newbody(CR,NULLBODY,NULLBODY); }
	;

empty	: /*empty*/
		{ $$=newbody(EMPTY,NULLBODY,NULLBODY); }
	;

annot	: ANNOT
		{ $$=$1; }
	| /*empty*/
		{ $$=NULL; }
	;

%%

