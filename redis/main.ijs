
load '../cffi/main.ijs'

NB. Redis interface


TYPES =:     	 ( 'redisContext';'err';'errstr')
TYPES =: TYPES; <( 'redisReply';  'type'; 'str';'len'; 'integer'; 'elements'; 'element')

REDIS_ERRS =: 'REDIS_ERR_IO REDIS_ERR_EOF REDIS_ERR_PROTOCOL REDIS_ERR_OOM REDIS_ERR_OTHER '

MACROS =: REDIS_ERRS
MACROS =: MACROS, 'REDIS_BLOCK REDIS_CONNECTED REDIS_REPLY_INTEGER REDIS_ERR REDIS_OK '
MACROS =: MACROS, 'REDIS_DISCONNECTING REDIS_FREEING REDIS_IN_CALLBACK REDIS_SUBSCRIBED '
MACROS =: MACROS, 'REDIS_MONITORING REDIS_REPLY_STRING REDIS_REPLY_ARRAY '
MACROS =: MACROS, 'REDIS_REPLY_NIL REDIS_REPLY_STATUS REDIS_REPLY_ERROR REDIS_READER_MAX_BUF'
MACROS =: ;: MACROS

HEADERS =: '<hiredis/hiredis.h>'
LIB     =: '/lib64/libhiredis.so '

REDIS_C_CFG =: HEADERS; MACROS; TYPES

cdf''

x =: build REDIS_C_CFG  

NB. redisConnect str-ip;port -- returns a pointer to a redisContext-pointer
redisConnect =: {. @ ((LIB,' redisConnect *c *c i') & cd )

NB. redisFree redisContext-pointer  -- returns nothing
redisFree =: (LIB,' redisFree  n *c') & cd @ <

NB. redisCommand redisContext-pointer;query  -- returns a redisReply-pointer
redisCommand =: {. @ ((LIB, ' redisCommand  *c *c *c') & cd)


NB. freeReplyObject redisReply-pointer -- retrunns nothing
freeReplyObject =: (LIB, ' freeReplyObject  n *c') & cd @ <

reply_auto_ii =: verb define
        type =:  y extract_int 'redisReply' ;'type'
        echo type
        select. type
                case. REDIS_REPLY_INTEGER do.  'integer' ; reply_int_i y
                case. REDIS_REPLY_STRING  do.  'string'  ; reply_str_i y
                case. REDIS_REPLY_STATUS  do.  'status'  ; reply_str_i y
                case. REDIS_REPLY_NIL     do.  'nil'     ; ''
                case. REDIS_REPLY_ARRAY   do.  'array'   ; 'auto' reply_array_i y
                case. REDIS_REPLY_ERROR   do.  'error'   ;  reply_str_i y
        end.
)
reply_auto_i =: >@{:@reply_auto_ii

NB. pretty_reply ctx;reply[;quiet]  -- return the reply or print error
NB.   return 0;reply on success or 1;'' on error
pretty_reply =: verb define
        'ctx reply quiet' =. ((,&(<0))^:(# = 2:)) y
        r =: reply_auto_ii reply
        echo r
        type =. > {. r
        rep  =. }. r
        select. type
                case. 'integer';'string';'status';'array' do. 0;rep
                case. 'error' do.
                      if. quiet = 0 do.
                          'err err_name errstr' =. context_error_i ctx
                          if. err do. 
                              echo 'Error: ', err_name, ' ', ": err
                              echo '   context-msg: ', errstr
                          else.
                                echo 'Error: ', (, > rep)
                          end.
                      end.
                      1;''
        end.          
)

redisCmd  =: verb define
        'ctx cmd' =. y
        reply =. redisCommand ctx;cmd
                      echo 'HELLO'
        res =. pretty_reply ctx;reply
        freeReplyObject reply
        res
)
redisConn =: verb define
         ctx =: redisConnect y
          if. >ctx do.
              'err err_name errstr' =. context_error_i ctx
              if. err do.
                  echo 'Error: ', (, err_name ), ' (', (": err), ') ' , errstr
              end.
              err;ctx
          end.
          1;''
)
NB. context_error_i ctx -- extract error info from ctx
context_error_i =: verb define        
        err =: y extract_int 'redisContext' ;'err'
        errstr =: y extract_chars 128; 'redisContext' ;'errstr'
        err_name =:>@(err&=@". @> # ]) ;: REDIS_ERRS
        
        err; err_name ;errstr
)

NB. reply_str_i redisReply-pointer -- returns a string from reply
reply_str_i =: verb define
	len =. y extract_size_t  'redisReply';'len'
	ptr =. y extract_pointer 'redisReply';'str'
        ptr read_str len
)
NB. reply_int_i redisReply-pointer -- returns a string from reply
reply_int_i =: verb define
          y extract_long 'redisReply';'integer'
)
NB. [cell-type] reply_array_i redisReply-pointer  -- returns a boxed rely
NB.   cell-type could be 'int','str','auto'
reply_array_i =: verb define
          'auto' reply_array_i y
          :
          elements =. y extract_size_t  'redisReply';'elements'
          if. elements do.
              element  =. y extract_pointer  'redisReply';'element'
              ps =. element read_pointer_n 0,elements
              ". '(<@reply_', x ,'_i@>)"0 ps'
          else.
              ''
          end.
)


NB. unit testing done right

doit =: verb define
       'err ctx' =: redisConn '127.0.0.1';6379
       if. err = 0 do.
       select. y
               case. 'base' do.             
                    echo CFFI_DATA_I
                    
                    echo sizeof 'redisReply'; 'str'
                    echo sizeof 'redisReply'; 'len'
                    echo offsetof 'redisReply'; 'str'
                    echo offsetof 'redisReply'; 'len'
                    r =: 'NOPE'
               case. 'str' do.
                     rep =: redisCommand ctx;'PING'
                     r =: reply_str_i rep
	             freeReplyObject rep
               case. 'int' do.              
                     rep =: redisCommand ctx;'INCR counter'
                     r   =: reply_int_i rep
       	             freeReplyObject rep
               case. 'list' do.
                     rep =: redisCommand ctx;'LRANGE mylist 0 -1'
                     r   =: 'auto'reply_array_i rep
                     freeReplyObject rep
               case. 'pstr' do.
                    r =: redisCmd ctx; 'PING'
               case. 'pint' do.
                    echo 'HELLO'
                    r =: redisCmd ctx;'INCR counter'
               case. 'plist' do.                    
                    r =: redisCmd ctx;'LRANGE mylist 0 -1'
               case. 'perr' do.
                      r =: redisCmd ctx;'GETas xmylist'
                      r =: redisCmd ctx;'LRANGE xmylist 0 -1'

      end.
      redisFree ctx
      r
      end.
)