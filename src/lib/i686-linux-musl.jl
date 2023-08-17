module Zlib_h

using Zlib_jll
export Zlib_jll

const __darwin_off_t = Int64

const off_t = __darwin_off_t

const Byte = Cuchar

const Bytef = Byte

const uInt = Cuint

const uLong = Culong

const charf = Cchar

const intf = Cint

const uIntf = uInt

const uLongf = uLong

const voidpc = Ptr{Cvoid}

const voidpf = Ptr{Cvoid}

const voidp = Ptr{Cvoid}

# typedef void * ( * alloc_func ) ( void * opaque , unsigned int items , unsigned int size )
const alloc_func = Ptr{Cvoid}

# typedef void ( * free_func ) ( void * opaque , void * address )
const free_func = Ptr{Cvoid}

mutable struct internal_state end

struct zng_stream_s
    next_in::Ptr{UInt8}
    avail_in::UInt32
    total_in::Csize_t
    next_out::Ptr{UInt8}
    avail_out::UInt32
    total_out::Csize_t
    msg::Ptr{Cchar}
    state::Ptr{internal_state}
    zalloc::alloc_func
    zfree::free_func
    opaque::Ptr{Cvoid}
    data_type::Cint
    adler::UInt32
    reserved::Culong
end

const zng_stream = zng_stream_s

const zng_streamp = Ptr{zng_stream}

struct zng_gz_header_s
    text::Int32
    time::Culong
    xflags::Int32
    os::Int32
    extra::Ptr{UInt8}
    extra_len::UInt32
    extra_max::UInt32
    name::Ptr{UInt8}
    name_max::UInt32
    comment::Ptr{UInt8}
    comm_max::UInt32
    hcrc::Int32
    done::Int32
end

const zng_gz_header = zng_gz_header_s

const zng_gz_headerp = Ptr{zng_gz_header}

function zlibng_version()
    ccall((:zlibng_version, Zlib_jll.libz_path), Ptr{Cchar}, ())
end

function zng_deflateInit(strm, level::Int32)
    ccall((:zng_deflateInit, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), strm, level)
end

function zng_deflate(strm, flush::Int32)
    ccall((:zng_deflate, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), strm, flush)
end

function zng_deflateEnd(strm)
    ccall((:zng_deflateEnd, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflateInit(strm)
    ccall((:zng_inflateInit, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflate(strm, flush::Int32)
    ccall((:zng_inflate, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), strm, flush)
end

function zng_inflateEnd(strm)
    ccall((:zng_inflateEnd, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_deflateInit2(strm, level::Int32, method::Int32, windowBits::Int32, memLevel::Int32, strategy::Int32)
    ccall((:zng_deflateInit2, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32, Int32, Int32, Int32, Int32), strm, level, method, windowBits, memLevel, strategy)
end

function zng_deflateSetDictionary(strm, dictionary, dictLength::UInt32)
    ccall((:zng_deflateSetDictionary, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, UInt32), strm, dictionary, dictLength)
end

function zng_deflateGetDictionary(strm, dictionary, dictLength)
    ccall((:zng_deflateGetDictionary, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, Ptr{UInt32}), strm, dictionary, dictLength)
end

function zng_deflateCopy(dest, source)
    ccall((:zng_deflateCopy, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{zng_stream}), dest, source)
end

function zng_deflateReset(strm)
    ccall((:zng_deflateReset, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_deflateParams(strm, level::Int32, strategy::Int32)
    ccall((:zng_deflateParams, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32, Int32), strm, level, strategy)
end

function zng_deflateTune(strm, good_length::Int32, max_lazy::Int32, nice_length::Int32, max_chain::Int32)
    ccall((:zng_deflateTune, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32, Int32, Int32, Int32), strm, good_length, max_lazy, nice_length, max_chain)
end

function zng_deflateBound(strm, sourceLen::Culong)
    ccall((:zng_deflateBound, Zlib_jll.libz_path), Culong, (Ptr{zng_stream}, Culong), strm, sourceLen)
end

function zng_deflatePending(strm, pending, bits)
    ccall((:zng_deflatePending, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{UInt32}, Ptr{Int32}), strm, pending, bits)
end

function zng_deflatePrime(strm, bits::Int32, value::Int32)
    ccall((:zng_deflatePrime, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32, Int32), strm, bits, value)
end

function zng_deflateSetHeader(strm, head::zng_gz_headerp)
    ccall((:zng_deflateSetHeader, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, zng_gz_headerp), strm, head)
end

function zng_inflateInit2(strm, windowBits::Int32)
    ccall((:zng_inflateInit2, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), strm, windowBits)
end

function zng_inflateSetDictionary(strm, dictionary, dictLength::UInt32)
    ccall((:zng_inflateSetDictionary, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, UInt32), strm, dictionary, dictLength)
end

function zng_inflateGetDictionary(strm, dictionary, dictLength)
    ccall((:zng_inflateGetDictionary, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, Ptr{UInt32}), strm, dictionary, dictLength)
end

function zng_inflateSync(strm)
    ccall((:zng_inflateSync, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflateCopy(dest, source)
    ccall((:zng_inflateCopy, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{zng_stream}), dest, source)
end

function zng_inflateReset(strm)
    ccall((:zng_inflateReset, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflateReset2(strm, windowBits::Int32)
    ccall((:zng_inflateReset2, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), strm, windowBits)
end

function zng_inflatePrime(strm, bits::Int32, value::Int32)
    ccall((:zng_inflatePrime, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32, Int32), strm, bits, value)
end

function zng_inflateMark(strm)
    ccall((:zng_inflateMark, Zlib_jll.libz_path), Clong, (Ptr{zng_stream},), strm)
end

function zng_inflateGetHeader(strm, head::zng_gz_headerp)
    ccall((:zng_inflateGetHeader, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, zng_gz_headerp), strm, head)
end

function zng_inflateBackInit(strm, windowBits::Int32, window)
    ccall((:zng_inflateBackInit, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32, Ptr{UInt8}), strm, windowBits, window)
end

# typedef uint32_t ( * in_func ) ( void * , const uint8_t * * )
const in_func = Ptr{Cvoid}

# typedef int32_t ( * out_func ) ( void * , uint8_t * , uint32_t )
const out_func = Ptr{Cvoid}

function zng_inflateBack(strm, in::in_func, in_desc, out::out_func, out_desc)
    ccall((:zng_inflateBack, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, in_func, Ptr{Cvoid}, out_func, Ptr{Cvoid}), strm, in, in_desc, out, out_desc)
end

function zng_inflateBackEnd(strm)
    ccall((:zng_inflateBackEnd, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_zlibCompileFlags()
    ccall((:zng_zlibCompileFlags, Zlib_jll.libz_path), Culong, ())
end

function zng_compress(dest, destLen, source, sourceLen::Csize_t)
    ccall((:zng_compress, Zlib_jll.libz_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t), dest, destLen, source, sourceLen)
end

function zng_compress2(dest, destLen, source, sourceLen::Csize_t, level::Int32)
    ccall((:zng_compress2, Zlib_jll.libz_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t, Int32), dest, destLen, source, sourceLen, level)
end

function zng_compressBound(sourceLen::Csize_t)
    ccall((:zng_compressBound, Zlib_jll.libz_path), Csize_t, (Csize_t,), sourceLen)
end

function zng_uncompress(dest, destLen, source, sourceLen::Csize_t)
    ccall((:zng_uncompress, Zlib_jll.libz_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t), dest, destLen, source, sourceLen)
end

function zng_uncompress2(dest, destLen, source, sourceLen)
    ccall((:zng_uncompress2, Zlib_jll.libz_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Ptr{Csize_t}), dest, destLen, source, sourceLen)
end

function zng_adler32(adler::UInt32, buf, len::UInt32)
    ccall((:zng_adler32, Zlib_jll.libz_path), UInt32, (UInt32, Ptr{UInt8}, UInt32), adler, buf, len)
end

function zng_adler32_z(adler::UInt32, buf, len::Csize_t)
    ccall((:zng_adler32_z, Zlib_jll.libz_path), UInt32, (UInt32, Ptr{UInt8}, Csize_t), adler, buf, len)
end

function zng_adler32_combine(adler1::UInt32, adler2::UInt32, len2::off_t)
    ccall((:zng_adler32_combine, Zlib_jll.libz_path), UInt32, (UInt32, UInt32, off_t), adler1, adler2, len2)
end

function zng_crc32(crc::UInt32, buf, len::UInt32)
    ccall((:zng_crc32, Zlib_jll.libz_path), UInt32, (UInt32, Ptr{UInt8}, UInt32), crc, buf, len)
end

function zng_crc32_z(crc::UInt32, buf, len::Csize_t)
    ccall((:zng_crc32_z, Zlib_jll.libz_path), UInt32, (UInt32, Ptr{UInt8}, Csize_t), crc, buf, len)
end

function zng_crc32_combine(crc1::UInt32, crc2::UInt32, len2::off_t)
    ccall((:zng_crc32_combine, Zlib_jll.libz_path), UInt32, (UInt32, UInt32, off_t), crc1, crc2, len2)
end

function zng_crc32_combine_gen(len2::off_t)
    ccall((:zng_crc32_combine_gen, Zlib_jll.libz_path), UInt32, (off_t,), len2)
end

function zng_crc32_combine_op(crc1::UInt32, crc2::UInt32, op::UInt32)
    ccall((:zng_crc32_combine_op, Zlib_jll.libz_path), UInt32, (UInt32, UInt32, UInt32), crc1, crc2, op)
end

@cenum zng_deflate_param::UInt32 begin
    Z_DEFLATE_LEVEL = 0
    Z_DEFLATE_STRATEGY = 1
    Z_DEFLATE_REPRODUCIBLE = 2
end

struct zng_deflate_param_value
    param::zng_deflate_param
    buf::Ptr{Cvoid}
    size::Csize_t
    status::Int32
end

function zng_deflateSetParams(strm, params, count::Csize_t)
    ccall((:zng_deflateSetParams, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{zng_deflate_param_value}, Csize_t), strm, params, count)
end

function zng_deflateGetParams(strm, params, count::Csize_t)
    ccall((:zng_deflateGetParams, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Ptr{zng_deflate_param_value}, Csize_t), strm, params, count)
end

function zng_zError(arg1::Int32)
    ccall((:zng_zError, Zlib_jll.libz_path), Ptr{Cchar}, (Int32,), arg1)
end

function zng_inflateSyncPoint(arg1)
    ccall((:zng_inflateSyncPoint, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), arg1)
end

function zng_get_crc_table()
    ccall((:zng_get_crc_table, Zlib_jll.libz_path), Ptr{UInt32}, ())
end

function zng_inflateUndermine(arg1, arg2::Int32)
    ccall((:zng_inflateUndermine, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), arg1, arg2)
end

function zng_inflateValidate(arg1, arg2::Int32)
    ccall((:zng_inflateValidate, Zlib_jll.libz_path), Int32, (Ptr{zng_stream}, Int32), arg1, arg2)
end

function zng_inflateCodesUsed(arg1)
    ccall((:zng_inflateCodesUsed, Zlib_jll.libz_path), Culong, (Ptr{zng_stream},), arg1)
end

function zng_inflateResetKeep(arg1)
    ccall((:zng_inflateResetKeep, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), arg1)
end

function zng_deflateResetKeep(arg1)
    ccall((:zng_deflateResetKeep, Zlib_jll.libz_path), Int32, (Ptr{zng_stream},), arg1)
end

# Skipping MacroDefinition: z_const const

const MAX_MEM_LEVEL = 9

const MAX_WBITS = 15

# Skipping MacroDefinition: Z_EXTERN extern

const ZNG_CONDEXPORT = Z_EXPORT

const z_off_t = off_t

const z_off64_t = z_off_t

const ZLIBNG_VERSION = "2.1.0.devel"

const ZLIBNG_VERNUM = Clong(0x02010000)

const ZLIBNG_VER_MAJOR = 2

const ZLIBNG_VER_MINOR = 1

const ZLIBNG_VER_REVISION = 0

const ZLIBNG_VER_STATUS = 0

const ZLIBNG_VER_MODIFIED = 0

const Z_NO_FLUSH = 0

const Z_PARTIAL_FLUSH = 1

const Z_SYNC_FLUSH = 2

const Z_FULL_FLUSH = 3

const Z_FINISH = 4

const Z_BLOCK = 5

const Z_TREES = 6

const Z_OK = 0

const Z_STREAM_END = 1

const Z_NEED_DICT = 2

const Z_ERRNO = -1

const Z_STREAM_ERROR = -2

const Z_DATA_ERROR = -3

const Z_MEM_ERROR = -4

const Z_BUF_ERROR = -5

const Z_VERSION_ERROR = -6

const Z_NO_COMPRESSION = 0

const Z_BEST_SPEED = 1

const Z_BEST_COMPRESSION = 9

const Z_DEFAULT_COMPRESSION = -1

const Z_FILTERED = 1

const Z_HUFFMAN_ONLY = 2

const Z_RLE = 3

const Z_FIXED = 4

const Z_DEFAULT_STRATEGY = 0

const Z_BINARY = 0

const Z_TEXT = 1

const Z_ASCII = Z_TEXT

const Z_UNKNOWN = 2

const Z_DEFLATED = 8

const Z_NULL = NULL

# exports
const PREFIXES = ["Z_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
