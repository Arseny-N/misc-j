
require 'strings'


NB. Shared Library Generation 
NB.

LIB_TEMPLATE =: 0 : 0
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>

#define DECL_LMACRO(m)         	 unsigned long _macro_##m (void)         { return m; 		  };
#define DECL_ST_SIZEOF(n, s, m)  unsigned long _sizeof_##n##_##m(void)   { return sizeof(s.m);    };
#define DECL_OFFSETOF(n, s, m) 	 unsigned long _offsetof_##n##_##m(void) { return offsetof(s, m); };
#define pointer *

#define DECL_SIZEOF(n, t) unsigned long _sizeof_##n (void) { return sizeof(t); }

DECL_SIZEOF(int, int)
DECL_SIZEOF(long, long)
DECL_SIZEOF(long_long, long long)
DECL_SIZEOF(pointer, void*)
DECL_SIZEOF(size_t, size_t)
DECL_SIZEOF(char, char)

)

NB. c_cfg -- (hdr0;hdr1;...);(macro1;macro2..);(st0; mem0; mem1;..);(st1; mem0; mem1; ...)
C_CFG =: ('<stdio.h>';'<unistd.h>');('macro1';'macro2');('struct hello';'x';'y');<('hello2';'x';'y')

ccfg_get_hdrs =: >@ (0&{)
ccfg_get_mcs  =: >@ (1&{)
ccfg_get_vars =: }. @ }. 
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

crender_sz_i=: dyad : '''DECL_ST_SIZEOF('', (type_to_name x) ,'', '' , (type_to_var x), '', '',  y,'')'',LF'
crender_sz  =: (>@{. (crender_sz_i"1 1) >@,.@}.)


NB. crender_ofs (struct0;mem0;mem1...);<(struct1;...)... -- generate 
NB.  offsetoffs for shared library
crender_ofs =:;@:>@:(crender_of each)

crender_of_i=: dyad : '''DECL_OFFSETOF('', (type_to_name x) ,'', '' , x, '', '',  y,'')'',LF'
crender_of  =: (>@{. (crender_of_i"1 1) >@,.@}.)

NB. crender_mcs 'MACRO0';'MACRO1'
crender_mcs =: ,@:(crender_mc"1)@:>
crender_mc  =: monad : '''DECL_LMACRO('',y,'')'',LF'

NB. crender_lib (hdr1;hdr2...);(struct0;mem0;mem1...);(struct1;...)... -- generate the library
crender_lib   =:  LIB_TEMPLATE"_, crender_headers@ccfg_get_hdrs  , (crender_vars"1)@ccfg_get_vars , crender_lib_i
crender_lib_i =:  crender_szs@ccfg_get_vars , crender_ofs@ccfg_get_vars , crender_mcs@ccfg_get_mcs



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

NB. macro_ii macro
macro_ii =: monad : '  '' _macro_'', y, '' l'''
NB. lib macro_i macro
macro_i =: >@(cd&'')@([ , macro_ii@])

NB. All data is stored is a global variable named CFFI_DATA_I
NB. CFFI_DATA_I =   ('type0';< ('mem0';(1,2));<('mem1';(2,3))) ,: ('type0';< ('mem0';(1,2));<('mem1';(2,3)))

NB. lib get_data (struct0;mem0;mem1...);<(struct1;...).. -- fill the CFFI_DATA_I variable
get_data =: dyad : ',. > (x&get_data_i) each y'

NB. lib get_data_i (struct0;mem0;mem1...)
get_data_i   =: >@{.@] ; <@get_data_ii
get_data_ii  =: [ get_data_iii"1 ({. ;&> }.)@]
get_data_iii =: ,@:>@:}.@:] ; sizeof_i , offsetof_i

NB. str0 streq str1 -- tests  weather str0 is equal to str1 works even if they are of different lengths
streq =: 0:`(*./@:=)@.(#@[ = #@])


NB. type;mem find_entry_i   DATA
find_entry_i =: ,@(>@}.@[ find_entry_i_mem"1 _ (>@{.@[ find_entry_i_type ]))
NB. type find_entry_i_type  DATA 
find_entry_i_type =: dyad : '> }. , {. y #~ > ((x&streq) each ({."1) y) '
find_entry_i_mem  =: dyad : '> }. , {. y #~"_1 > ((x&streq) each ({."1) y) '

NB. lib declare_macros PREFIX ; macro0; macro1; ...
NB. get_macros =: ( {. ,&> }. )@]  ,"1 (' =: '"_) ,"1 ":@( [ macro_i"1 >@}.@])
get_macros =: "."1 @: (( {. ,&> }. )@]  ,"1 (' =: '"_) ,"1 ":@( [ macro_i"1 >@}.@]))

declare_verbs =: verb define 
	sizeof   =: {.@(find_entry_i&y)
	offsetof =: }.@(find_entry_i&y)
	''
)

NB. Building and Configuration
NB.

NB. Build lifecycle
NB. 
NB. BEGIN   - create directories/files might be set to `nothing`
NB.   |
NB.   V
NB. generating path,'/',cfile
NB.   |
NB.   V
NB. mk_obj - create ofile 
NB.   |
NB.   V
NB. mk_dll - create dll 
NB.   |
NB.   V
NB. cleanup - leave the build directory clean
NB.   |
NB.   V
NB.  END    - remove the build directory  might be set to `nothing`
NB. 
NB. [On Error]
NB.    |
NB.    V
NB.   ERR    - remode build directory with all files  might be set to `nothing`

NB. parse_confing cfg -- crate a build-cfg 'object'
NB.  cfg - J code, the following variables might be set to affect the build
NB.    macro_prefix  -- a prefix to declared macros
NB.    path          -- path to the directory where the build is taking place
NB.                     path is prefixed to lib/cfile/ofile vars, if one of the
NB.                     latter will be changed path _will_not_ be prepended automatically
NB.    cfile/ofile   -- files used during build
NB.    lib           -- library name
NB.    BEGIN/END/ERR
NB.    mk_{dll,obj}
NB.    cleanup       -- see build lifecycle
NB.  Additional functions:
NB.    pjoin p0;p1;.. -- joins paths p0 p1 ..
NB.  Note: contents of a variable might be boxed, if done so then the data inside the box is
NB.        executed as a shell expression with (2!:0) othrewise it is treated as J code and
NB.        executed with ".
NB. Example:
NB.   B_CFG =: parse_confing (0 : 0)
NB.	path =. '/tmp/j-cffi-build-' , ": ? 5000
NB.     ERR  =. <'echo Noooo'
NB.     END  =. <'echo Debugging ; ls ', path
NB.   )
parse_confing =: verb define  
	pjoin  =. '/'&joinstring @ (*@>@(# each) # ])
	ifnn   =. [ ` ] @. (2: = L.@[)
	'path cfile ofile lib mk_obj mk_dll' =. 6 $ <<<''
	'macro_prefix BEGIN END ERR' =. 4 $ <<<''
	nothing =. ''
       
	res    =. ". each (LF cut y)

	macro_prefix  =. macro_prefix ifnn ''
	path   =. path ifnn 'build-jcffi',' 0' charsub , ('-'&,@":)"0 ? 4 # 9999
	cfile  =. pjoin path; cfile ifnn 'lib_src.c'
	ofile  =. pjoin path; ofile ifnn 'lib_src.o'
	lib    =. pjoin path; lib   ifnn 'libjcffi.so'
	
	BEGIN  =. BEGIN ifnn <'mkdir -p ', path
	END    =. END ifnn <'/bin/rm -d  ',path
	ERR    =. ERR ifnn <'/bin/rm -rf ',path

	mk_obj =. <'gcc -c -Wall  -fpic ',cfile,' -o ',ofile
	mk_dll =. <'gcc -shared -o ',lib,' ',ofile
	cleanup=. <'/bin/rm ', ofile , ' ' , cfile, ' ', lib
	cfile;lib;macro_prefix;BEGIN;END;ERR;<( mk_obj; mk_dll; <cleanup)
)



sh_exec =: dyad : '((2!:0) ] echo@(''Running sh ['', x ,'']: ''&,)) y'
j_exec  =: dyad : '(". [ echo@(''Running J  ['', x ,'']: ''&,)) y'

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

NB. b_cfg -- cfile; lib; BEGIN; END; ERR; <(mk_obj; <mk_dll; <cleanup)


NB. c_cfg build_i b_cfg -- build the c library and extract the data
NB.   to the CFFI_DATA_I variable
build_i =: dyad define
		
	'cfile lib macro_prefix BEGIN END ERR mk' =:  y
	'mk_obj mk_dll cleanup'   =: mk

	lib_text =. deb crender_lib x
	

	try.
	 	'BEGIN  ' run BEGIN
	 	echo 'Outputting lib text to ', cfile
	 	NB. echo lib_text
		lib_text fwrite cfile
		'mk_obj ' run mk_obj
		'mk_dll ' run mk_dll
                NB. TODO
		CFFI_DATA_I =: lib get_data ccfg_get_vars x
		declare_verbs CFFI_DATA_I
		lib declare_itypes ('char';'int';'long';'long_long';'pointer';'size_t')

		lib get_macros macro_prefix ; ccfg_get_mcs x

	 	'cleanup' run cleanup
		'END    ' run END	
	catchd.
		echo 'Error encountered.'
		'ERR    ' run ERR
	end.
        ''
)

NB. build c_cfg 
build =: build_i&(parse_confing '')

NB. Integer Utils
NB.
NB. Utils to facilitate cross-platform development
NB. 


NB. lib declare_itypes itype0; itype1 -- declares {sizeof,read,extract}_itype0  nouns.
NB.  Use declare_itypes to allow transparent heandling of 'obscure' integer types like size_t, pid_t ..
declare_itypes =: dyad :  'x&declare_itype each y'


ITYPE_TEMPLATE_I =: 0 : 0
         NB. sizeof_TYPE -- size of TYPE
         sizeof_TYPE =: > ('LIB _sizeof_TYPE l ')   cd ''
         NB. addr read_TYPE_n offset,num
         ". 'read_TYPE_n   =: read_s' , (": 8 * sizeof_TYPE), '_n'
         NB. addr read_TYPE offset
         read_TYPE       =: [ read_TYPE_n (,&1)@]
         
         NB.  ptr extract_TYPE n;st;mem
         extract_TYPEs   =: >@[  read_TYPE_n   (offsetof@:}. , >@{.)@]
         NB.  ptr extract_TYPE st;mem
         extract_TYPE    =: [ {.@extract_TYPEs (1&;)@]
)
NB. lib declare_itype type0
declare_itype =: (". each)@(LF&cut)@(stringreplace&ITYPE_TEMPLATE_I)@( 'TYPE'&;@] , 'LIB'&;@[ )

NB. addr read_{sign}{nbits}_n offset,num -- reads n nbit C integers from addr and casts
NB.   them to n J integers  according to sign
read_s64_n =:  (_3&(3!:4)) @ memr @ ([ , {.@] , 8&*@}.@] )
read_s32_n =:  (_2&(3!:4)) @ memr @ ([ , {.@] , 4&*@}.@] )
read_s16_n =:  (_1&(3!:4)) @ memr @ ([ , {.@] , 2&*@}.@] )
read_u16_n =:  ( 0&(3!:4)) @ memr @ ([ , {.@] , 2&*@}.@] )

NB. addr read_str offset,len
read_str_i =: read_s8_n =: memr @ ([ , {.@] , }.@] )
read_str   =: [ read_str_i (0&,)@]






