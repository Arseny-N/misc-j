# Miscellaneous J scripts

This project was made as a class project for a systems programming class 
at the ITMO university. A report in Russian giving a short introduction to 
the J language and describing in somewhat more detail the code is available 
as `report.pdf`.

## C FFI with J

J has quite minimalistic C FFI capabilities, namely `'<library> <funtion> <signature>' cd '<arg1> <arg2>..'`
allows to call a function in a shared library, `memr addr, offset, num [,size]` allows to read data form `addr + offset*size` to `addr + offset + num*size`.

The cffi library extends the capabilities of J by adding functions to work with arbitrary C types and structures.

Here is an example usage:
```J
NB. rep is a pointer to redisReply
len =. rep extract_size_t  'redisReply';'len'
ptr =. rep extract_pointer 'redisReply';'str'
ptr read_str len NB. returns the string
```

## Redis

The following functions are implemented:

- `redisConn addr;port` - returns a pointed to `redisContext`, `addr` and `pert` are the address and port of the redis server.
- `redisFree` - frees a  `redisContext`
- `redisCmd ctx;cmd` - executes a redis command and returns a result.

`redisCmd` is implemented using a lower level API:

- `redisCommand ctx;cmd` - executes a redis command and returns a `redisReply`.
- `freeReplyObject` - frees a `redisReply`.

- `reply_str_i, reply_num_i, reply_array_i` -  extracts string/number/array data form a `redisReply` structure.
- `reply_auto_i`  - extracts data form a `redisReply` structure guessing it's type.


Example usage:

```J
'err ctx' =: redisConn '127.0.0.1';6379
if. err = 0 do.
  r =: redisCmd ctx; 'PING' NB. r = 'PONG'
  r =: redisCmd ctx;'INCR counter' NB. r = 1
end.
redisFree ctx
```

