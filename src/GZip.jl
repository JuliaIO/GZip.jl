## gzip file io

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
