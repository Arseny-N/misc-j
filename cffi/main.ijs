

NB. Build a shared library 


LIB_TEMPLATE =: 0 : 0
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#define DECL_LMACRO(m)         unsigned long _macro_##m (void)         { return m 		};
#define DECL_SIZEOF(n, s, m)   unsigned long _sizeof_##n##_##m(void)   { return sizeof(s.m);    };
#define DECL_OFFSETOF(n, s, m) unsigned long _offsetof_##n##_##m(void) { return offsetof(s, m); };
#define pointer *
)


 




NB. Shared Library Generation 
NB.

NB. c_cfg -- (hdr0;hdr1;...);(st0; mem0; mem1;..);(st1; mem0; mem1; ...)
C_CFG =: ('<stdio.h>';'<unistd.h>');('struct hello';'x';'y');<('hello2';'x';'y')

NB. crender_headers hdr1;hdr2... -- generate headers for shared library
crender_headers =: (,&LF)@,@:((,"1)&LF)@:('#include '&(,"1))@:>
NB. strip_struct str -- strips struuct qalifier from data type if present
strip_struct =: (}.^:({. = ' '"_)) @ ((' struct ';'') & stringreplace) @(' '&,)@deb

NB. crender_variables (struct0;mem0;mem1...);<(struct1;...)... -- generate 
NB.  variables for shared library
crender_vars =: ,@:>@:(crender_var@>@{. each)
crender_var  =: (,&(';',LF))@((,&'  ')@] , type_to_var)

NB. type_to_name typename -- convert typename to a string usabel in declarations
type_to_name =: (' ';'_') & stringreplace @ deb

type_to_var =: (,&'_var')@strip_struct

NB. crender_szs (struct0;mem0;mem1...);<(struct1;...)... -- generate 
NB.  sizeoffs for shared library
crender_szs =:;@:>@:(crender_sz each)

crender_sz_i=: dyad : '''DECL_SIZEOF('', (type_to_name x) ,'', '' , (type_to_var x), '', '',  y,'')'',LF'
crender_sz  =: (>@{. (crender_sz_i"1 1) >@,.@}.)


NB. crender_ofs (struct0;mem0;mem1...);<(struct1;...)... -- generate 
NB.  offsetoffs for shared library
crender_ofs =:;@:>@:(crender_of each)

crender_of_i=: dyad : '''DECL_OFFSETOF('', (type_to_name x) ,'', '' , x, '', '',  y,'')'',LF'
crender_of  =: (>@{. (crender_of_i"1 1) >@,.@}.)

NB. crender_lib (hdr1;hdr2...);(struct0;mem0;mem1...);(struct1;...)... -- generate the library
crender_lib  =:  LIB_TEMPLATE"_, crender_headers@>@{.  , (crender_vars"1)@}. , crender_szs@}. , crender_ofs@}.



NB. Data Extaction
NB. 


NB. type sizeof_ii mem
sizeof_ii =: dyad : ' '' _sizeof_'',(type_to_name x),''_'',y , '' l'' '
NB. lib sizeof_i type;mem  
sizeof_i  =:  >@(cd&'')@ (  [ , ({. sizeof_ii&> {:)@] )
NB. b_cfg sizeof type
NB. sizeof =: >@(1&{)@[ sizeof_i ]


NB. type offsetof_ii mem
offsetof_ii =: dyad : ' '' _offsetof_'',(type_to_name x),''_'',y , '' l'' '
NB. lib offsetof_i type;mem
offsetof_i  =: >@(cd&'')@(  [ , ({. offsetof_ii&> {:)@] )
NB. b_cfg offsetof type;mem
NB. offsetof =: >@(1&{)@[ offsetof_i ]

NB. All data is stored is a global variable named CFFI_DATA_I
NB. CFFI_DATA_I =   ('type0';< ('mem0';(1,2));<('mem1';(2,3))) ,: ('type0';< ('mem0';(1,2));<('mem1';(2,3)))

NB. lib get_data (struct0;mem0;mem1...);<(struct1;...).. -- fill the CFFI_DATA_I variable
get_data =: dyad : ',. > (x&get_data_i) each y'

NB. lib get_data_i (struct0;mem0;mem1...)
get_data_i   =: >@{.@] ; <@get_data_ii
get_data_ii  =: [ get_data_iii"1 ({. ;&> }.)@]
get_data_iii =: ,@:>@:}.@:] ; sizeof_i , offsetof_i


NB. type;mem find_entry_i   DATA
find_entry_i =: ,@(>@}.@[ find_entry_i_mem"1 _ (>@{.@[ find_entry_i_type ]))
NB. type find_entry_i_type  DATA 
find_entry_i_type =: dyad : '> }. , {. y #~ > ((x&streq) each ({."1) y) '
find_entry_i_mem  =: dyad : '> }. , {. y #~"_1 > ((x&streq) each ({."1) y) '



sizeof   =: {.@(find_entry_i&CFFI_DATA_I)
offsetof =: }.@(find_entry_i&CFFI_DATA_I)

NB. Configuration

NB. parse_confing = verb define
pc =: verb define  
	pjoin  =. '/'&joinstring @ (*@>@(# each) # ])
	ifnn   =. [ ` ] @. (2: = L.@[)
	'path cfile ofile lib mk_obj mk_dll' =. 6 $ <<<''
	'BEGIN END' =. '[';'['
	res    =. ". y
	

	path   =. path ifnn 'build'
	cfile  =. pjoin path; cfile ifnn 'test.c'
	ofile  =. pjoin path; ofile ifnn 'test.o'
	lib    =. pjoin path; lib   ifnn 'libtest.so'
	
	BEGIN  =. <'mkdir build'
	END    =. <'/bin/rm -d build'
	
	mk_obj =. <'gcc -c -Wall  -fpic ',cfile,' -o ',ofile
	mk_dll =. <'gcc -shared -o ',lib,' ',ofile
	cleanup=. <'/bin/rm ', ofile , ' ' , cfile, ' ', lib
	cfile;lib;BEGIN;END;<( mk_obj; mk_dll; <cleanup)
)



sh_exec =: dyad : '((2!:0) ] echo@(''Running sh ['', x ,'']: ''&,)) y'
j_exec  =: dyad : '(". [ echo@(''Running J ['', x ,'']: ''&,)) y'

NB. msg run str -- if str is boxed then it gets executed
NB.  and the eecution result  is returned of not then 
NB.  str is intrpreted as J code
run =: dyad define 
	if. 1 = (L. y) do. 
		x sh_exec >y
	else.
		x j_exec y
	end.
)
NB. run =: j_exec`(sh_exec@<) @. (1: = L.)

NB. Building

NB. b_cfg -- cfile; lib; BEGIN; END; <mk_obj; <mk_dll; <cleanup
B_CFG =: pc ''

NB. c_cfg build b_cfg 
build =: dyad define
		
	'cfile lib BEGIN END mk' =:  y
	'mk_obj mk_dll cleanup'   =: mk

	lib_text =. crender_lib x
	

	
 	'BEGIN  ' run BEGIN
 	echo 'Outputting lib text to ', cfile
	lib_text fwrite cfile
	'mk_obj ' run mk_obj
	'mk_dll ' run mk_dll
	CFFI_DATA_I =: lib get_data }. x
 	'cleanup' run cleanup
	'END    ' run END	
)

NB. REDIS_C_CFG =: ('<hiredis/hiredis.h>');('redisContext';'err';'errstr');<( 'redisReply'; 'type';'str';'len')

Y =:     ('redisContext';'err';'errstr')
Y =: Y; <( 'redisReply'; 'type'; 'str';'len'; 'integer'; 'elements'; 'element')

Y =: ('<hiredis/hiredis.h>') ; Y

REDIS_C_CFG =: Y

cdf''
x =: REDIS_C_CFG build B_CFG 

echo sizeof 'redisReply'; 'str'
echo sizeof 'redisReply'; 'len'

echo offsetof 'redisReply'; 'str'
echo offsetof 'redisReply'; 'len'


NB. Redis interface

LIB =: '/lib64/libhiredis.so '
NB. redisConnect str-ip;port -- returns a pointer to a redisContext-pointer
redisConnect =: <@{. @ ((LIB,' redisConnect *c *c i') & cd )
NB. redisFree redisContext-pointer  -- returns nothing
redisFree =: (LIB,' redisFree  n *c') & cd
NB. redisCommand redisContext-pointer;query  -- returns a redisRequest
redisCommand =: (LIB, ' redisCommand  *c *c *c') & cd



doit =: verb define
	ctx =: redisConnect '127.0.0.1';6379
	
	redisFree ctx
)




