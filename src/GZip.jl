## gzip file io

"""
GZip.jl: A Julia interface for gzip functions in zlib

This module provides a wrapper for the gzip related functions of
([zlib](http://zlib.net/)), a free, general-purpose, legally
unencumbered, lossless data-compression library. These functions allow
the reading and writing of gzip files.

## Notes

-   This interface is only for gzipped files, not the streaming zlib
    compression interface. Internally, it depends on/uses the
    streaming interface, but the gzip related functions are higher
    level functions pertaining to gzip files only.
-   `GZipStream` is an implementation of `IO` and can be used virtually
    anywhere `IO` is used.
-   This implementation mimics the `IOStream` implementation, and should be a
    drop-in replacement for `IOStream`, with some caveats:
    -   `seekend` and `truncate` are not available
    -   `readuntil` is available, but is not very efficient. (But `readline` works fine.)

In addition to [`open`](@ref), [`gzopen`](@ref), and [`gzdopen`](@ref), the
following `IO`/`IOStream` functions are supported:

-   `close()`
-   `flush()`
-   `seek()`
-   `skip()`
-   `position()`
-   `eof()`
-   `read()`
-   `readuntil()`
-   `readline()`
-   `write()`
-   `peek()`

Due to limitations in `zlib`, `seekend` and `truncate` are not available.
"""
module GZip

using Libdl
using Base.Libc

import Base: show, fd, close, flush, truncate, seek,
             seekend, skip, position, eof, read,
             readline, write, unsafe_write, peek

export
  GZipStream,
  show,

# io functions
# open,  ## not exported; use as GZip.open(...)
  gzopen,
  gzdopen,
  fd,
  close,
  flush,
  truncate,
  seek,
  skip,
  position,
  eof,
  read,
  readline,
  write,
  unsafe_write,
  peek,

# lower-level io functions
  gzgetc,
  gzungetc,
  gzgets,
  gzputc,
  gzwrite,
  gzread,
  gzbuffer,

# File offset
  ZFileOffset,

# GZError, ZError, related constants (zlib_h.jl)
  GZError,
  ZError,
  Z_OK,
  Z_STREAM_END,
  Z_NEED_DICT,
  Z_ERRNO,
  Z_STREAM_ERROR,
  Z_DATA_ERROR,
  Z_MEM_ERROR,
  Z_BUF_ERROR,
  Z_VERSION_ERROR,

# Compression constants (zlib_h.jl)
  Z_NO_COMPRESSION,
  Z_BEST_SPEED,
  Z_BEST_COMPRESSION,
  Z_DEFAULT_COMPRESSION,

# Compression strategy (zlib_h.jl)
  Z_FILTERED,
  Z_HUFFMAN_ONLY,
  Z_RLE,
  Z_FIXED,
  Z_DEFAULT_STRATEGY,

# Default buffer sizes
  Z_DEFAULT_BUFSIZE,
  Z_BIG_BUFSIZE

# End export

include("zlib.jl")
include("gz.jl")

end # module GZip
