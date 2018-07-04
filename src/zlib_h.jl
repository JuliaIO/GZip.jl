# general zlib constants, definitions

using Compat.Sys: isunix, iswindows

@static if isunix()
    const _zlib = "libz"
elseif iswindows()
    const _zlib = "zlib1"
end

# Constants

zlib_version =  unsafe_string(ccall((:zlibVersion, _zlib), Ptr{UInt8}, ()))
ZLIB_VERSION = tuple([parse(Int, c) for c in split(zlib_version, '.')]...)

# Flush values
const Z_NO_FLUSH       =  Int32(0)
const Z_PARTIAL_FLUSH  =  Int32(1)
const Z_SYNC_FLUSH     =  Int32(2)
const Z_FULL_FLUSH     =  Int32(3)
const Z_FINISH         =  Int32(4)
const Z_BLOCK          =  Int32(5)
const Z_TREES          =  Int32(6)

# Return codes
const Z_OK             =  Int32(0)
const Z_STREAM_END     =  Int32(1)
const Z_NEED_DICT      =  Int32(2)
const Z_ERRNO          =  Int32(-1)
const Z_STREAM_ERROR   =  Int32(-2)
const Z_DATA_ERROR     =  Int32(-3)
const Z_MEM_ERROR      =  Int32(-4)
const Z_BUF_ERROR      =  Int32(-5)
const Z_VERSION_ERROR  =  Int32(-6)


# Zlib errors as Exceptions
zerror(e::Integer) =  unsafe_string(ccall((:zError, _zlib), Ptr{UInt8}, (Int32,), e))
mutable struct ZError <: Exception
    err::Int32
    err_str::AbstractString

    ZError(e::Integer) = (e == Z_ERRNO ? new(e, strerror()) : new(e, zerror(e)))
end

# Compression Levels
const Z_NO_COMPRESSION      =  Int32(0)
const Z_BEST_SPEED          =  Int32(1)
const Z_BEST_COMPRESSION    =  Int32(9)
const Z_DEFAULT_COMPRESSION =  Int32(-1)

# Compression Strategy
const Z_FILTERED             =  Int32(1)
const Z_HUFFMAN_ONLY         =  Int32(2)
const Z_RLE                  =  Int32(3)
const Z_FIXED                =  Int32(4)
const Z_DEFAULT_STRATEGY     =  Int32(0)

# data_type field
const Z_BINARY    =  Int32(0)
const Z_TEXT      =  Int32(1)
const Z_ASCII     = Z_TEXT
const Z_UNKNOWN   =  Int32(2)

# deflate compression method
const Z_DEFLATED    =  Int32(8)

# misc
const Z_NULL   = C_NULL

# Constants for use with gzbuffer
const Z_DEFAULT_BUFSIZE = 8192
const Z_BIG_BUFSIZE = 131072

# Constants for use with gzseek
const SEEK_SET =  Int32(0)
const SEEK_CUR =  Int32(1)

# Create ZFileOffset alias
# Use 64bit if the *64 functions are available or zlib is compiles with 64bit
# file offset.

# Get compile-time option flags
const zlib_compile_flags = ccall((:zlibCompileFlags, _zlib), UInt, ())
const z_off_t_sz = 2 << ((zlib_compile_flags >> 6) & UInt(3))
if z_off_t_sz == 8 || (!iswindows() && Libdl.dlsym_e(Libdl.dlopen(_zlib), :gzopen64) != C_NULL)
    const ZFileOffset = Int64
elseif z_off_t_sz == 4
    const ZFileOffset = Int32
else
    error("Can't figure out what to do with ZFileOffset. sizeof(z_off_t) = ", z_off_t_sz)
end
