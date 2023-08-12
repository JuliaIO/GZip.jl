module Zlib_h

using Zlib_jll
export Zlib_jll

const z_size_t = Csize_t

const Byte = Cuchar

const uInt = Cuint

const uLong = Culong

const Bytef = Byte

const uLongf = uLong

const voidpc = Ptr{Cvoid}

const voidpf = Ptr{Cvoid}

const voidp = Ptr{Cvoid}

const z_crc_t = Culong

const __darwin_off_t = Int64

const off_t = __darwin_off_t

function zlibVersion()
    ccall((:zlibVersion, Zlib_jll.libz_path), Ptr{Cchar}, ())
end

mutable struct internal_state end

# typedef voidpf ( * alloc_func ) OF
const alloc_func = Ptr{Cvoid}

# typedef void ( * free_func ) OF
const free_func = Ptr{Cvoid}

struct z_stream_s
    next_in::Ptr{Bytef}
    avail_in::uInt
    total_in::uLong
    next_out::Ptr{Bytef}
    avail_out::uInt
    total_out::uLong
    msg::Ptr{Cchar}
    state::Ptr{internal_state}
    zalloc::alloc_func
    zfree::free_func
    opaque::voidpf
    data_type::Cint
    adler::uLong
    reserved::uLong
end

const z_stream = z_stream_s

const z_streamp = Ptr{z_stream}

function deflateInit_(strm::z_streamp, level::Cint, version, stream_size::Cint)
    ccall((:deflateInit_, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Ptr{Cchar}, Cint), strm, level, version, stream_size)
end

function inflateInit_(strm::z_streamp, version, stream_size::Cint)
    ccall((:inflateInit_, Zlib_jll.libz_path), Cint, (z_streamp, Ptr{Cchar}, Cint), strm, version, stream_size)
end

function deflateInit2_(strm::z_streamp, level::Cint, method::Cint, windowBits::Cint, memLevel::Cint, strategy::Cint, version, stream_size::Cint)
    ccall((:deflateInit2_, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Cint, Cint, Cint, Cint, Ptr{Cchar}, Cint), strm, level, method, windowBits, memLevel, strategy, version, stream_size)
end

function inflateInit2_(strm::z_streamp, windowBits::Cint, version, stream_size::Cint)
    ccall((:inflateInit2_, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Ptr{Cchar}, Cint), strm, windowBits, version, stream_size)
end

function inflateBackInit_(strm::z_streamp, windowBits::Cint, window, version, stream_size::Cint)
    ccall((:inflateBackInit_, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Ptr{Cuchar}, Ptr{Cchar}, Cint), strm, windowBits, window, version, stream_size)
end

struct gzFile_s
    have::Cuint
    next::Ptr{Cuchar}
    pos::off_t
end

const gzFile = Ptr{gzFile_s}

function gzopen64(arg1, arg2)
    ccall((:gzopen64, Zlib_jll.libz_path), gzFile, (Ptr{Cchar}, Ptr{Cchar}), arg1, arg2)
end

function gzseek64(arg1::gzFile, arg2::Clong, arg3::Cint)
    ccall((:gzseek64, Zlib_jll.libz_path), Clong, (gzFile, Clong, Cint), arg1, arg2, arg3)
end

function gztell64(arg1::gzFile)
    ccall((:gztell64, Zlib_jll.libz_path), Clong, (gzFile,), arg1)
end

function gzoffset64(arg1::gzFile)
    ccall((:gzoffset64, Zlib_jll.libz_path), Clong, (gzFile,), arg1)
end

function adler32_combine64(arg1::uLong, arg2::uLong, arg3::Clong)
    ccall((:adler32_combine64, Zlib_jll.libz_path), uLong, (uLong, uLong, Clong), arg1, arg2, arg3)
end

function crc32_combine64(arg1::uLong, arg2::uLong, arg3::Clong)
    ccall((:crc32_combine64, Zlib_jll.libz_path), uLong, (uLong, uLong, Clong), arg1, arg2, arg3)
end

function crc32_combine_gen64(arg1::Clong)
    ccall((:crc32_combine_gen64, Zlib_jll.libz_path), uLong, (Clong,), arg1)
end

struct gz_header_s
    text::Cint
    time::uLong
    xflags::Cint
    os::Cint
    extra::Ptr{Bytef}
    extra_len::uInt
    extra_max::uInt
    name::Ptr{Bytef}
    name_max::uInt
    comment::Ptr{Bytef}
    comm_max::uInt
    hcrc::Cint
    done::Cint
end

const gz_header = gz_header_s

const gz_headerp = Ptr{gz_header}

function deflate(strm::z_streamp, flush::Cint)
    ccall((:deflate, Zlib_jll.libz_path), Cint, (z_streamp, Cint), strm, flush)
end

function deflateEnd(strm::z_streamp)
    ccall((:deflateEnd, Zlib_jll.libz_path), Cint, (z_streamp,), strm)
end

function inflate(strm::z_streamp, flush::Cint)
    ccall((:inflate, Zlib_jll.libz_path), Cint, (z_streamp, Cint), strm, flush)
end

function inflateEnd(strm::z_streamp)
    ccall((:inflateEnd, Zlib_jll.libz_path), Cint, (z_streamp,), strm)
end

function deflateSetDictionary(strm::z_streamp, dictionary, dictLength::uInt)
    ccall((:deflateSetDictionary, Zlib_jll.libz_path), Cint, (z_streamp, Ptr{Bytef}, uInt), strm, dictionary, dictLength)
end

function deflateGetDictionary(strm::z_streamp, dictionary, dictLength)
    ccall((:deflateGetDictionary, Zlib_jll.libz_path), Cint, (z_streamp, Ptr{Bytef}, Ptr{uInt}), strm, dictionary, dictLength)
end

function deflateCopy(dest::z_streamp, source::z_streamp)
    ccall((:deflateCopy, Zlib_jll.libz_path), Cint, (z_streamp, z_streamp), dest, source)
end

function deflateReset(strm::z_streamp)
    ccall((:deflateReset, Zlib_jll.libz_path), Cint, (z_streamp,), strm)
end

function deflateParams(strm::z_streamp, level::Cint, strategy::Cint)
    ccall((:deflateParams, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Cint), strm, level, strategy)
end

function deflateTune(strm::z_streamp, good_length::Cint, max_lazy::Cint, nice_length::Cint, max_chain::Cint)
    ccall((:deflateTune, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Cint, Cint, Cint), strm, good_length, max_lazy, nice_length, max_chain)
end

function deflateBound(strm::z_streamp, sourceLen::uLong)
    ccall((:deflateBound, Zlib_jll.libz_path), uLong, (z_streamp, uLong), strm, sourceLen)
end

function deflatePending(strm::z_streamp, pending, bits)
    ccall((:deflatePending, Zlib_jll.libz_path), Cint, (z_streamp, Ptr{Cuint}, Ptr{Cint}), strm, pending, bits)
end

function deflatePrime(strm::z_streamp, bits::Cint, value::Cint)
    ccall((:deflatePrime, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Cint), strm, bits, value)
end

function deflateSetHeader(strm::z_streamp, head::gz_headerp)
    ccall((:deflateSetHeader, Zlib_jll.libz_path), Cint, (z_streamp, gz_headerp), strm, head)
end

function inflateSetDictionary(strm::z_streamp, dictionary, dictLength::uInt)
    ccall((:inflateSetDictionary, Zlib_jll.libz_path), Cint, (z_streamp, Ptr{Bytef}, uInt), strm, dictionary, dictLength)
end

function inflateGetDictionary(strm::z_streamp, dictionary, dictLength)
    ccall((:inflateGetDictionary, Zlib_jll.libz_path), Cint, (z_streamp, Ptr{Bytef}, Ptr{uInt}), strm, dictionary, dictLength)
end

function inflateSync(strm::z_streamp)
    ccall((:inflateSync, Zlib_jll.libz_path), Cint, (z_streamp,), strm)
end

function inflateCopy(dest::z_streamp, source::z_streamp)
    ccall((:inflateCopy, Zlib_jll.libz_path), Cint, (z_streamp, z_streamp), dest, source)
end

function inflateReset(strm::z_streamp)
    ccall((:inflateReset, Zlib_jll.libz_path), Cint, (z_streamp,), strm)
end

function inflateReset2(strm::z_streamp, windowBits::Cint)
    ccall((:inflateReset2, Zlib_jll.libz_path), Cint, (z_streamp, Cint), strm, windowBits)
end

function inflatePrime(strm::z_streamp, bits::Cint, value::Cint)
    ccall((:inflatePrime, Zlib_jll.libz_path), Cint, (z_streamp, Cint, Cint), strm, bits, value)
end

function inflateMark(strm::z_streamp)
    ccall((:inflateMark, Zlib_jll.libz_path), Clong, (z_streamp,), strm)
end

function inflateGetHeader(strm::z_streamp, head::gz_headerp)
    ccall((:inflateGetHeader, Zlib_jll.libz_path), Cint, (z_streamp, gz_headerp), strm, head)
end

# typedef unsigned ( * in_func ) OF
const in_func = Ptr{Cvoid}

# typedef int ( * out_func ) OF
const out_func = Ptr{Cvoid}

function inflateBack(strm::z_streamp, in::in_func, in_desc, out::out_func, out_desc)
    ccall((:inflateBack, Zlib_jll.libz_path), Cint, (z_streamp, in_func, Ptr{Cvoid}, out_func, Ptr{Cvoid}), strm, in, in_desc, out, out_desc)
end

function inflateBackEnd(strm::z_streamp)
    ccall((:inflateBackEnd, Zlib_jll.libz_path), Cint, (z_streamp,), strm)
end

function zlibCompileFlags()
    ccall((:zlibCompileFlags, Zlib_jll.libz_path), uLong, ())
end

function compress(dest, destLen, source, sourceLen::uLong)
    ccall((:compress, Zlib_jll.libz_path), Cint, (Ptr{Bytef}, Ptr{uLongf}, Ptr{Bytef}, uLong), dest, destLen, source, sourceLen)
end

function compress2(dest, destLen, source, sourceLen::uLong, level::Cint)
    ccall((:compress2, Zlib_jll.libz_path), Cint, (Ptr{Bytef}, Ptr{uLongf}, Ptr{Bytef}, uLong, Cint), dest, destLen, source, sourceLen, level)
end

function compressBound(sourceLen::uLong)
    ccall((:compressBound, Zlib_jll.libz_path), uLong, (uLong,), sourceLen)
end

function uncompress(dest, destLen, source, sourceLen::uLong)
    ccall((:uncompress, Zlib_jll.libz_path), Cint, (Ptr{Bytef}, Ptr{uLongf}, Ptr{Bytef}, uLong), dest, destLen, source, sourceLen)
end

function uncompress2(dest, destLen, source, sourceLen)
    ccall((:uncompress2, Zlib_jll.libz_path), Cint, (Ptr{Bytef}, Ptr{uLongf}, Ptr{Bytef}, Ptr{uLong}), dest, destLen, source, sourceLen)
end

function gzdopen(fd::Cint, mode)
    ccall((:gzdopen, Zlib_jll.libz_path), gzFile, (Cint, Ptr{Cchar}), fd, mode)
end

function gzbuffer(file::gzFile, size::Cuint)
    ccall((:gzbuffer, Zlib_jll.libz_path), Cint, (gzFile, Cuint), file, size)
end

function gzsetparams(file::gzFile, level::Cint, strategy::Cint)
    ccall((:gzsetparams, Zlib_jll.libz_path), Cint, (gzFile, Cint, Cint), file, level, strategy)
end

function gzread(file::gzFile, buf::voidp, len::Cuint)
    ccall((:gzread, Zlib_jll.libz_path), Cint, (gzFile, voidp, Cuint), file, buf, len)
end

function gzfread(buf::voidp, size::z_size_t, nitems::z_size_t, file::gzFile)
    ccall((:gzfread, Zlib_jll.libz_path), z_size_t, (voidp, z_size_t, z_size_t, gzFile), buf, size, nitems, file)
end

function gzwrite(file::gzFile, buf::voidpc, len::Cuint)
    ccall((:gzwrite, Zlib_jll.libz_path), Cint, (gzFile, voidpc, Cuint), file, buf, len)
end

function gzfwrite(buf::voidpc, size::z_size_t, nitems::z_size_t, file::gzFile)
    ccall((:gzfwrite, Zlib_jll.libz_path), z_size_t, (voidpc, z_size_t, z_size_t, gzFile), buf, size, nitems, file)
end

function gzputs(file::gzFile, s)
    ccall((:gzputs, Zlib_jll.libz_path), Cint, (gzFile, Ptr{Cchar}), file, s)
end

function gzgets(file::gzFile, buf, len::Cint)
    ccall((:gzgets, Zlib_jll.libz_path), Ptr{Cchar}, (gzFile, Ptr{Cchar}, Cint), file, buf, len)
end

function gzputc(file::gzFile, c::Cint)
    ccall((:gzputc, Zlib_jll.libz_path), Cint, (gzFile, Cint), file, c)
end

function gzungetc(c::Cint, file::gzFile)
    ccall((:gzungetc, Zlib_jll.libz_path), Cint, (Cint, gzFile), c, file)
end

function gzflush(file::gzFile, flush::Cint)
    ccall((:gzflush, Zlib_jll.libz_path), Cint, (gzFile, Cint), file, flush)
end

function gzrewind(file::gzFile)
    ccall((:gzrewind, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function gzeof(file::gzFile)
    ccall((:gzeof, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function gzdirect(file::gzFile)
    ccall((:gzdirect, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function gzclose(file::gzFile)
    ccall((:gzclose, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function gzclose_r(file::gzFile)
    ccall((:gzclose_r, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function gzclose_w(file::gzFile)
    ccall((:gzclose_w, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function gzerror(file::gzFile, errnum)
    ccall((:gzerror, Zlib_jll.libz_path), Ptr{Cchar}, (gzFile, Ptr{Cint}), file, errnum)
end

function gzclearerr(file::gzFile)
    ccall((:gzclearerr, Zlib_jll.libz_path), Cvoid, (gzFile,), file)
end

function adler32(adler::uLong, buf, len::uInt)
    ccall((:adler32, Zlib_jll.libz_path), uLong, (uLong, Ptr{Bytef}, uInt), adler, buf, len)
end

function adler32_z(adler::uLong, buf, len::z_size_t)
    ccall((:adler32_z, Zlib_jll.libz_path), uLong, (uLong, Ptr{Bytef}, z_size_t), adler, buf, len)
end

function crc32(crc::uLong, buf, len::uInt)
    ccall((:crc32, Zlib_jll.libz_path), uLong, (uLong, Ptr{Bytef}, uInt), crc, buf, len)
end

function crc32_z(crc::uLong, buf, len::z_size_t)
    ccall((:crc32_z, Zlib_jll.libz_path), uLong, (uLong, Ptr{Bytef}, z_size_t), crc, buf, len)
end

function crc32_combine_op(crc1::uLong, crc2::uLong, op::uLong)
    ccall((:crc32_combine_op, Zlib_jll.libz_path), uLong, (uLong, uLong, uLong), crc1, crc2, op)
end

function gzgetc_(file::gzFile)
    ccall((:gzgetc_, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function zError(arg1::Cint)
    ccall((:zError, Zlib_jll.libz_path), Ptr{Cchar}, (Cint,), arg1)
end

function inflateSyncPoint(arg1::z_streamp)
    ccall((:inflateSyncPoint, Zlib_jll.libz_path), Cint, (z_streamp,), arg1)
end

function get_crc_table()
    ccall((:get_crc_table, Zlib_jll.libz_path), Ptr{z_crc_t}, ())
end

function inflateUndermine(arg1::z_streamp, arg2::Cint)
    ccall((:inflateUndermine, Zlib_jll.libz_path), Cint, (z_streamp, Cint), arg1, arg2)
end

function inflateValidate(arg1::z_streamp, arg2::Cint)
    ccall((:inflateValidate, Zlib_jll.libz_path), Cint, (z_streamp, Cint), arg1, arg2)
end

function inflateCodesUsed(arg1::z_streamp)
    ccall((:inflateCodesUsed, Zlib_jll.libz_path), Culong, (z_streamp,), arg1)
end

function inflateResetKeep(arg1::z_streamp)
    ccall((:inflateResetKeep, Zlib_jll.libz_path), Cint, (z_streamp,), arg1)
end

function deflateResetKeep(arg1::z_streamp)
    ccall((:deflateResetKeep, Zlib_jll.libz_path), Cint, (z_streamp,), arg1)
end

const ZLIB_VERSION = "1.2.13"

const ZLIB_VERNUM = 0x12d0

const ZLIB_VER_MAJOR = 1

const ZLIB_VER_MINOR = 2

const ZLIB_VER_REVISION = 13

const ZLIB_VER_SUBREVISION = 0

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

const Z_NULL = 0

const zlib_version = zlibVersion()

const gzopen = gzopen64

const gzseek = gzseek64

const gztell = gztell64

const gzoffset = gzoffset64

const adler32_combine = adler32_combine64

const crc32_combine = crc32_combine64

const crc32_combine_gen = crc32_combine_gen64

# exports
const PREFIXES = ["Z_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
