
require '../cffi/main.ijs'

NB. Redis interface

NB. REDIS_C_CFG =: ('<hiredis/hiredis.h>');('redisContext';'err';'errstr');<( 'redisReply'; 'type';'str';'len')

Y =:     ( 'redisContext';'err';'errstr')
Y =: Y; <( 'redisReply';  'type'; 'str';'len'; 'integer'; 'elements'; 'element')

Y =: ('<hiredis/hiredis.h>') ; ( 'REDIS_REPLY_STRING';'REDIS_REPLY_ERROR' );Y

TYPES =:     	 ( 'redisContext';'err';'errstr')
TYPES =: TYPES; <( 'redisReply';  'type'; 'str';'len'; 'integer'; 'elements'; 'element')

MACROS =: 'REDIS_ERR REDIS_OK REDIS_ERR_IO REDIS_ERR_EOF REDIS_ERR_PROTOCOL REDIS_ERR_OOM '
MACROS =: MACROS, 'REDIS_ERR_OTHER REDIS_BLOCK REDIS_CONNECTED REDIS_REPLY_INTEGER '
MACROS =: MACROS, 'REDIS_DISCONNECTING REDIS_FREEING REDIS_IN_CALLBACK REDIS_SUBSCRIBED '
MACROS =: MACROS, 'REDIS_MONITORING REDIS_REPLY_STRING REDIS_REPLY_ARRAY '
MACROS =: MACROS, 'REDIS_REPLY_NIL REDIS_REPLY_STATUS REDIS_REPLY_ERROR REDIS_READER_MAX_BUF'
MACROS =: ;: MACROS

HEADERS =: '<hiredis/hiredis.h>'

X =: HEADERS; MACROS; TYPES

REDIS_C_CFG =: X

cdf''
x =: REDIS_C_CFG build B_CFG 

NB. unit testing done right
echo CFFI_DATA_I
echo sizeof 'redisReply'; 'str'
echo sizeof 'redisReply'; 'len'

echo offsetof 'redisReply'; 'str'
echo offsetof 'redisReply'; 'len'




LIB =: '/lib64/libhiredis.so '
NB. redisConnect str-ip;port -- returns a pointer to a redisContext-pointer
redisConnect =: {. @ ((LIB,' redisConnect *c *c i') & cd )

NB. redisFree redisContext-pointer  -- returns nothing
redisFree =: (LIB,' redisFree  n *c') & cd @ <

NB. redisCommand redisContext-pointer;query  -- returns a redisReply-pointer
redisCommand =: {. @ ((LIB, ' redisCommand  *c *c *c') & cd)


NB. freeReplyObject redisReply-pointer -- retrunns nothing
freeReplyObject =: (LIB, ' freeReplyObject  n *c') & cd @ <

reply_auto =: verb define
           ''
)

NB. reply_str redisReply-pointer -- returns a string from reply
reply_str =: verb define
	len =. y extract_size_t  'redisReply';'len'
	ptr =. y extract_pointer 'redisReply';'str'
        ptr read_str len
)
NB. reply_int redisReply-pointer -- returns a string from reply
reply_int =: verb define
          y extract_long 'redisReply';'integer'
)
NB. [cell-type] reply_array redisReply-pointer  -- returns a boxed rely
NB.   cell-type could be 'int','str','auto'
reply_array =: dyad define
          elements =. y extract_size_t  'redisReply';'elements'
          element  =. y extract_pointer  'redisReply';'element'
          ps =. element read_pointer_n 0,elements
          ". '(<@reply_', x ,'@>)"0 ps'
)
doit =: verb define
       ctx =: redisConnect '127.0.0.1';6379
       select. y
               case. 'str' do.
                     rep =: redisCommand ctx;'PING'
                     r =: reply_str rep
	             freeReplyObject rep
               case. 'int' do.              
                     rep =: redisCommand ctx;'INCR counter'
                     r   =: reply_int rep
       	             freeReplyObject rep
               case. 'list' do.
                     rep =: redisCommand ctx;'LRANGE mylist 0 -1'
                     r   =: 'str' reply_array rep
                     freeReplyObject rep

      end.
      redisFree ctx
      r; rep
)