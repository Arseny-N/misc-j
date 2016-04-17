

NB. Inline documentation and testing module 
MODULE =: ''

streq 	=. 0:`(*./@:=)@.(#@[ = #@])
bstr_safe_ix =. (<'')"_`{@.([ < #@])
str_safe_ix  =. (>@bstr_safe_ix)"0 1
num_safe_ix  =. (0"_`{@.([ < #@]))"0 1
remove_el =. -.@= # ]

NB. Check if a text line is a J comment
is_comment  =. ('NB'&streq)@>@{.@('.'&cut)

NB. Check if a text line is a J global assigment
NB. Note: ;: does not split lines with comments, so  
NB. 1 bstr_safe_ix (;: line) will always 
NB. be 'empty' for comment lines
is_assiment  =. ('=:'&streq)@>@(1&bstr_safe_ix)@;:
is_assimentp =. ('=:'&streq +. '=.'&streq)@>@(1&bstr_safe_ix)@;:

NB. Reads a file in a boxed table where each col is a text line
read_file =. ( LF&remove_el each) @ }.@ (<;.1) @ (LF&,) @ (1!:1)


NB. reset_docs'' reset global DOCUMENTATION variable
reset_docs =: verb define
	DOCUMENTATION =: ''
)

reset_docs''


NB. x load_docs_i file -- load documentation from file, and return result.
NB.
NB.  If x is 0 then docs for only global assigments will 
NB.  be loaded if x is 1 then docs for private assigments 
NB.  will also be imported. load_docs_i returens the docs
NB.  it does not alter the global DOCUMENTATION variable.
load_docs_i =: dyad define
	text =. read_file <y

	cm =. > @: (is_comment each)  text
	
	as =. > @: (is_assiment`is_assimentp@.x each) text

	'cm_ix as_ix' =. (I. cm) ; I. as

	doc_as =. as_ix {~ (#as_ix) remove_el as_ix  i. (1 + cm_ix)
	read_names =.  >@{.@;: each doc_as { text

	is_cm_line =. ({&cm)
	read_comm0 =. (''"_)`($:@<:@[ , {&text) @. is_cm_line
	read_comm  =. < @:( (}.^:3) each) @read_comm0

	read_comms =. (read_comm"0) doc_as - 1
	docs =.  read_names ,. read_comms
)

NB. load_docs file -- loads documentation for global assigments from file
NB.
NB.  Extracts comments before global and (optioanlly) local assigments and adds their 
NB.  contents to the DOCUMENTATION global variable.  Comments should be placed
NB.  exactly before the assigment line without additional blank lines.
load_docs =: verb define
	docs =. 0 load_docs_i y
	DOCUMENTATION =: ~. DOCUMENTATION,docs	
	(({."1) docs) ,. ( > each (}."1) docs)
)

find_docs_d =: dyad : '> > {: , y #~ (> ((x&streq) each {."1 y))'

find_docs =: find_docs_d&DOCUMENTATION

NB. doc func_name -- print documnetation for function `func_name`
NB.
NB.  Documentation is extracted from DOCUMENTATION global variable 
doc =: verb define
	 
	TAB =. '    '
	


	echo 'Docs   :'
	dc =.  'No docs!'"_^:(0: = #) (find_docs y)

	
	echo TAB ,"1 dc

	try. 	rank =. ":". y,' b.0'	 
		echo 'Rank   : ',rank
	catch. 	echo 'Rank   : ','----'	 end.	
	
	try. 	obverse =. ":". y,' b._1'
		echo 'Obverse: ',obverse
	catch.	echo 'Obverse: ','----'	 end.

	try. 	id =. ":". y,' b._1'
		echo 'Neutral: ',id
	catch. 	echo 'Neutral: ','----'	 end.

	
)



is_test  =. ( '.'&= +. ':'&= ) @ {.
get_tests =. }."1 @: ( is_test"1 @ ] # ])

space =. 32 { a.
tab   =. 9 { a.

NB. 1 - execute line (zero or two or more spaces/tabs)
NB. 0 - test wether the output of the previous executed line 
NB. matches the current line (one space/tab)
parse_test =. ((~:&1)@+/"1@:>@ (0 1&num_safe_ix)@(space&= +. tab&=))

NB. function run_tests_i docs -- run tests where docs are the docs and function is 
NB. a function name. 
NB. 
NB.  Returns number of (failed tests; number of succesful tests; `reports`)
NB.  format of a `report`: 
NB.           test line index; test; expected result; actual result
NB.  Note: no idea, about varable scopes and stuff but they seem to work - local varables are local
NB.  to tests, global are global and local function variables are visible inside tests, the last one is a bug..
run_tests_i =: dyad define
NB. docs   =. 1 load_docs_i 
	tests  =. get_tests x find_docs_d y
	ptests =. parse_test"1 tests
	prev   =. ''
	fail   =. 0
	succ   =. 0
	reports =. ''
	for_i. i.#tests do.
		line =. dltb i { tests
		if. i { ptests do. prev =. ":". line
		else. 

			if. prev streq line do. 
				succ =. succ + 1
			else.
				fail =. fail + 1		
				prev_st =. dltb (i-1) { tests
				
NB.				msg =. 'error[', (":i) ,']: ''', prev_st 
NB.				msg =. msg, ''' does not equal to ''', line, ''' but reults in ''', prev, ''''  
NB.				echo msg
				reports =. reports ,:^:(0:~:#@[)  (i; prev_st; line; prev)
			end.
		end.
	end.
	fail; succ; < reports 
)

NB. run_tests file -- runs test inside file
NB. 
NB.  If the comment line starts with NB.. followed by two or zero spaces
NB.  or tabs then that line is interpreted and executed as J code. If that line
NB.  is followed by a similar comment line i.e. NB.. aand _one_ space or tab then
NB.  the resultes of the previous statement are combared with the results of that 
NB.  line.
run_tests =: verb define
	docs =. 1 load_docs_i y
	Z =. 'CM LINE';'TEST';'EXPECTED';'GOT'
	tests =. (] ,.  >@((run_tests_i&docs) each) ) ({."1 docs) 
NB.	non_empty =. (*@+/@:>@:(1 2 {"1)) tests
NB.	non_empty #:_ tests
	
	
	nempty =.(*@(+/)@:>@( (1 2)&{"1))	
	tests =. (nempty # ]) tests
NB.	tests =. ( (0 1 2 )&{ , ( (Z&,)@ (,:^:(1: = $@$)) each) @ (3&{))"1 tests
	tests =. ( (0 1 2 )&{ , ( (Z&,) each) @ (3&{))"1 tests
	tests =. ('FUNCTION';'FAIL';'SUCC'; 'REP'), tests
	tests
)



