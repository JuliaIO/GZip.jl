module ZlibNG_h

using ZlibNG_jll
export ZlibNG_jll

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
    ccall((:zlibng_version, ZlibNG_jll.libzng_path), Ptr{Cchar}, ())
end

function zng_deflateInit(strm, level::Int32)
    ccall((:zng_deflateInit, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), strm, level)
end

function zng_deflate(strm, flush::Int32)
    ccall((:zng_deflate, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), strm, flush)
end

function zng_deflateEnd(strm)
    ccall((:zng_deflateEnd, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflateInit(strm)
    ccall((:zng_inflateInit, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflate(strm, flush::Int32)
    ccall((:zng_inflate, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), strm, flush)
end

function zng_inflateEnd(strm)
    ccall((:zng_inflateEnd, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_deflateInit2(strm, level::Int32, method::Int32, windowBits::Int32, memLevel::Int32, strategy::Int32)
    ccall((:zng_deflateInit2, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32, Int32, Int32, Int32, Int32), strm, level, method, windowBits, memLevel, strategy)
end

function zng_deflateSetDictionary(strm, dictionary, dictLength::UInt32)
    ccall((:zng_deflateSetDictionary, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, UInt32), strm, dictionary, dictLength)
end

function zng_deflateGetDictionary(strm, dictionary, dictLength)
    ccall((:zng_deflateGetDictionary, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, Ptr{UInt32}), strm, dictionary, dictLength)
end

function zng_deflateCopy(dest, source)
    ccall((:zng_deflateCopy, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{zng_stream}), dest, source)
end

function zng_deflateReset(strm)
    ccall((:zng_deflateReset, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_deflateParams(strm, level::Int32, strategy::Int32)
    ccall((:zng_deflateParams, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32, Int32), strm, level, strategy)
end

function zng_deflateTune(strm, good_length::Int32, max_lazy::Int32, nice_length::Int32, max_chain::Int32)
    ccall((:zng_deflateTune, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32, Int32, Int32, Int32), strm, good_length, max_lazy, nice_length, max_chain)
end

function zng_deflateBound(strm, sourceLen::Culong)
    ccall((:zng_deflateBound, ZlibNG_jll.libzng_path), Culong, (Ptr{zng_stream}, Culong), strm, sourceLen)
end

function zng_deflatePending(strm, pending, bits)
    ccall((:zng_deflatePending, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{UInt32}, Ptr{Int32}), strm, pending, bits)
end

function zng_deflatePrime(strm, bits::Int32, value::Int32)
    ccall((:zng_deflatePrime, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32, Int32), strm, bits, value)
end

function zng_deflateSetHeader(strm, head::zng_gz_headerp)
    ccall((:zng_deflateSetHeader, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, zng_gz_headerp), strm, head)
end

function zng_inflateInit2(strm, windowBits::Int32)
    ccall((:zng_inflateInit2, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), strm, windowBits)
end

function zng_inflateSetDictionary(strm, dictionary, dictLength::UInt32)
    ccall((:zng_inflateSetDictionary, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, UInt32), strm, dictionary, dictLength)
end

function zng_inflateGetDictionary(strm, dictionary, dictLength)
    ccall((:zng_inflateGetDictionary, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{UInt8}, Ptr{UInt32}), strm, dictionary, dictLength)
end

function zng_inflateSync(strm)
    ccall((:zng_inflateSync, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflateCopy(dest, source)
    ccall((:zng_inflateCopy, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{zng_stream}), dest, source)
end

function zng_inflateReset(strm)
    ccall((:zng_inflateReset, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_inflateReset2(strm, windowBits::Int32)
    ccall((:zng_inflateReset2, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), strm, windowBits)
end

function zng_inflatePrime(strm, bits::Int32, value::Int32)
    ccall((:zng_inflatePrime, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32, Int32), strm, bits, value)
end

function zng_inflateMark(strm)
    ccall((:zng_inflateMark, ZlibNG_jll.libzng_path), Clong, (Ptr{zng_stream},), strm)
end

function zng_inflateGetHeader(strm, head::zng_gz_headerp)
    ccall((:zng_inflateGetHeader, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, zng_gz_headerp), strm, head)
end

function zng_inflateBackInit(strm, windowBits::Int32, window)
    ccall((:zng_inflateBackInit, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32, Ptr{UInt8}), strm, windowBits, window)
end

# typedef uint32_t ( * in_func ) ( void * , const uint8_t * * )
const in_func = Ptr{Cvoid}

# typedef int32_t ( * out_func ) ( void * , uint8_t * , uint32_t )
const out_func = Ptr{Cvoid}

function zng_inflateBack(strm, in::in_func, in_desc, out::out_func, out_desc)
    ccall((:zng_inflateBack, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, in_func, Ptr{Cvoid}, out_func, Ptr{Cvoid}), strm, in, in_desc, out, out_desc)
end

function zng_inflateBackEnd(strm)
    ccall((:zng_inflateBackEnd, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), strm)
end

function zng_zlibCompileFlags()
    ccall((:zng_zlibCompileFlags, ZlibNG_jll.libzng_path), Culong, ())
end

function zng_compress(dest, destLen, source, sourceLen::Csize_t)
    ccall((:zng_compress, ZlibNG_jll.libzng_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t), dest, destLen, source, sourceLen)
end

function zng_compress2(dest, destLen, source, sourceLen::Csize_t, level::Int32)
    ccall((:zng_compress2, ZlibNG_jll.libzng_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t, Int32), dest, destLen, source, sourceLen, level)
end

function zng_compressBound(sourceLen::Csize_t)
    ccall((:zng_compressBound, ZlibNG_jll.libzng_path), Csize_t, (Csize_t,), sourceLen)
end

function zng_uncompress(dest, destLen, source, sourceLen::Csize_t)
    ccall((:zng_uncompress, ZlibNG_jll.libzng_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Csize_t), dest, destLen, source, sourceLen)
end

function zng_uncompress2(dest, destLen, source, sourceLen)
    ccall((:zng_uncompress2, ZlibNG_jll.libzng_path), Int32, (Ptr{UInt8}, Ptr{Csize_t}, Ptr{UInt8}, Ptr{Csize_t}), dest, destLen, source, sourceLen)
end

struct gzFile_s
    have::Cuint
    next::Ptr{Cuchar}
    pos::off_t
end

const gzFile = Ptr{gzFile_s}

function zng_gzopen(path, mode)
    ccall((:zng_gzopen, ZlibNG_jll.libzng_path), gzFile, (Ptr{Cchar}, Ptr{Cchar}), path, mode)
end

function zng_gzdopen(fd::Cint, mode)
    ccall((:zng_gzdopen, ZlibNG_jll.libzng_path), gzFile, (Cint, Ptr{Cchar}), fd, mode)
end

function zng_gzbuffer(file::gzFile, size::UInt32)
    ccall((:zng_gzbuffer, ZlibNG_jll.libzng_path), Int32, (gzFile, UInt32), file, size)
end

function zng_gzsetparams(file::gzFile, level::Int32, strategy::Int32)
    ccall((:zng_gzsetparams, ZlibNG_jll.libzng_path), Int32, (gzFile, Int32, Int32), file, level, strategy)
end

function zng_gzread(file::gzFile, buf, len::UInt32)
    ccall((:zng_gzread, ZlibNG_jll.libzng_path), Int32, (gzFile, Ptr{Cvoid}, UInt32), file, buf, len)
end

function zng_gzfread(buf, size::Csize_t, nitems::Csize_t, file::gzFile)
    ccall((:zng_gzfread, ZlibNG_jll.libzng_path), Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, gzFile), buf, size, nitems, file)
end

function zng_gzwrite(file::gzFile, buf, len::UInt32)
    ccall((:zng_gzwrite, ZlibNG_jll.libzng_path), Int32, (gzFile, Ptr{Cvoid}, UInt32), file, buf, len)
end

function zng_gzfwrite(buf, size::Csize_t, nitems::Csize_t, file::gzFile)
    ccall((:zng_gzfwrite, ZlibNG_jll.libzng_path), Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, gzFile), buf, size, nitems, file)
end

function zng_gzputs(file::gzFile, s)
    ccall((:zng_gzputs, ZlibNG_jll.libzng_path), Int32, (gzFile, Ptr{Cchar}), file, s)
end

function zng_gzgets(file::gzFile, buf, len::Int32)
    ccall((:zng_gzgets, ZlibNG_jll.libzng_path), Ptr{Cchar}, (gzFile, Ptr{Cchar}, Int32), file, buf, len)
end

function zng_gzputc(file::gzFile, c::Int32)
    ccall((:zng_gzputc, ZlibNG_jll.libzng_path), Int32, (gzFile, Int32), file, c)
end

function zng_gzungetc(c::Int32, file::gzFile)
    ccall((:zng_gzungetc, ZlibNG_jll.libzng_path), Int32, (Int32, gzFile), c, file)
end

function zng_gzflush(file::gzFile, flush::Int32)
    ccall((:zng_gzflush, ZlibNG_jll.libzng_path), Int32, (gzFile, Int32), file, flush)
end

function zng_gzseek(file::gzFile, offset::off_t, whence::Cint)
    ccall((:zng_gzseek, ZlibNG_jll.libzng_path), off_t, (gzFile, off_t, Cint), file, offset, whence)
end

function zng_gzrewind(file::gzFile)
    ccall((:zng_gzrewind, ZlibNG_jll.libzng_path), Int32, (gzFile,), file)
end

function zng_gztell(file::gzFile)
    ccall((:zng_gztell, ZlibNG_jll.libzng_path), off_t, (gzFile,), file)
end

function zng_gzoffset(file::gzFile)
    ccall((:zng_gzoffset, ZlibNG_jll.libzng_path), off_t, (gzFile,), file)
end

function zng_gzeof(file::gzFile)
    ccall((:zng_gzeof, ZlibNG_jll.libzng_path), Int32, (gzFile,), file)
end

function zng_gzdirect(file::gzFile)
    ccall((:zng_gzdirect, ZlibNG_jll.libzng_path), Int32, (gzFile,), file)
end

function zng_gzclose(file::gzFile)
    ccall((:zng_gzclose, ZlibNG_jll.libzng_path), Int32, (gzFile,), file)
end

function zng_gzclose_r(file::gzFile)
    ccall((:zng_gzclose_r, ZlibNG_jll.libzng_path), Int32, (gzFile,), file)
end

function zng_gzclose_w(file::gzFile)
    ccall((:zng_gzclose_w, ZlibNG_jll.libzng_path), Int32, (gzFile,), file)
end

function zng_gzerror(file::gzFile, errnum)
    ccall((:zng_gzerror, ZlibNG_jll.libzng_path), Ptr{Cchar}, (gzFile, Ptr{Int32}), file, errnum)
end

function zng_gzclearerr(file::gzFile)
    ccall((:zng_gzclearerr, ZlibNG_jll.libzng_path), Cvoid, (gzFile,), file)
end

function zng_adler32(adler::UInt32, buf, len::UInt32)
    ccall((:zng_adler32, ZlibNG_jll.libzng_path), UInt32, (UInt32, Ptr{UInt8}, UInt32), adler, buf, len)
end

function zng_adler32_z(adler::UInt32, buf, len::Csize_t)
    ccall((:zng_adler32_z, ZlibNG_jll.libzng_path), UInt32, (UInt32, Ptr{UInt8}, Csize_t), adler, buf, len)
end

function zng_adler32_combine(adler1::UInt32, adler2::UInt32, len2::off_t)
    ccall((:zng_adler32_combine, ZlibNG_jll.libzng_path), UInt32, (UInt32, UInt32, off_t), adler1, adler2, len2)
end

function zng_crc32(crc::UInt32, buf, len::UInt32)
    ccall((:zng_crc32, ZlibNG_jll.libzng_path), UInt32, (UInt32, Ptr{UInt8}, UInt32), crc, buf, len)
end

function zng_crc32_z(crc::UInt32, buf, len::Csize_t)
    ccall((:zng_crc32_z, ZlibNG_jll.libzng_path), UInt32, (UInt32, Ptr{UInt8}, Csize_t), crc, buf, len)
end

function zng_crc32_combine(crc1::UInt32, crc2::UInt32, len2::off_t)
    ccall((:zng_crc32_combine, ZlibNG_jll.libzng_path), UInt32, (UInt32, UInt32, off_t), crc1, crc2, len2)
end

function zng_crc32_combine_gen(len2::off_t)
    ccall((:zng_crc32_combine_gen, ZlibNG_jll.libzng_path), UInt32, (off_t,), len2)
end

function zng_crc32_combine_op(crc1::UInt32, crc2::UInt32, op::UInt32)
    ccall((:zng_crc32_combine_op, ZlibNG_jll.libzng_path), UInt32, (UInt32, UInt32, UInt32), crc1, crc2, op)
end

@enum zng_deflate_param::UInt32 begin
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
    ccall((:zng_deflateSetParams, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{zng_deflate_param_value}, Csize_t), strm, params, count)
end

function zng_deflateGetParams(strm, params, count::Csize_t)
    ccall((:zng_deflateGetParams, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Ptr{zng_deflate_param_value}, Csize_t), strm, params, count)
end

function zng_zError(arg1::Int32)
    ccall((:zng_zError, ZlibNG_jll.libzng_path), Ptr{Cchar}, (Int32,), arg1)
end

function zng_inflateSyncPoint(arg1)
    ccall((:zng_inflateSyncPoint, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), arg1)
end

function zng_get_crc_table()
    ccall((:zng_get_crc_table, ZlibNG_jll.libzng_path), Ptr{UInt32}, ())
end

function zng_inflateUndermine(arg1, arg2::Int32)
    ccall((:zng_inflateUndermine, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), arg1, arg2)
end

function zng_inflateValidate(arg1, arg2::Int32)
    ccall((:zng_inflateValidate, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream}, Int32), arg1, arg2)
end

function zng_inflateCodesUsed(arg1)
    ccall((:zng_inflateCodesUsed, ZlibNG_jll.libzng_path), Culong, (Ptr{zng_stream},), arg1)
end

function zng_inflateResetKeep(arg1)
    ccall((:zng_inflateResetKeep, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), arg1)
end

function zng_deflateResetKeep(arg1)
    ccall((:zng_deflateResetKeep, ZlibNG_jll.libzng_path), Int32, (Ptr{zng_stream},), arg1)
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
