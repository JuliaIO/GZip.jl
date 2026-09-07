module Zlib_h

using Zlib_jll
export Zlib_jll

function zlibVersion()
    ccall((:zlibVersion, Zlib_jll.libz_path), Ptr{Cchar}, ())
end

function zlibCompileFlags()
    ccall((:zlibCompileFlags, Zlib_jll.libz_path), Culong, ())
end

# Determine z_off_t size from compile flags (bits 6-7)
const _zlib_compile_flags = zlibCompileFlags()
const _z_off_t_sz = 2 << ((_zlib_compile_flags >> 6) & UInt(3))
const z_off_t = _z_off_t_sz == 8 ? Int64 : Int32

struct gzFile_s
    have::Cuint
    next::Ptr{Cuchar}
    pos::z_off_t
end

const gzFile = Ptr{gzFile_s}

function gzopen(arg1, arg2)
    ccall((:gzopen, Zlib_jll.libz_path), gzFile, (Ptr{Cchar}, Ptr{Cchar}), arg1, arg2)
end

function gzseek(arg1::gzFile, arg2::z_off_t, arg3::Cint)
    ccall((:gzseek, Zlib_jll.libz_path), z_off_t, (gzFile, z_off_t, Cint), arg1, arg2, arg3)
end

function gztell(arg1::gzFile)
    ccall((:gztell, Zlib_jll.libz_path), z_off_t, (gzFile,), arg1)
end

function gzoffset(arg1::gzFile)
    ccall((:gzoffset, Zlib_jll.libz_path), z_off_t, (gzFile,), arg1)
end

function gzdopen(fd::Cint, mode)
    ccall((:gzdopen, Zlib_jll.libz_path), gzFile, (Cint, Ptr{Cchar}), fd, mode)
end

function gzbuffer(file::gzFile, size::Cuint)
    ccall((:gzbuffer, Zlib_jll.libz_path), Cint, (gzFile, Cuint), file, size)
end

function gzread(file::gzFile, buf, len::Cuint)
    ccall((:gzread, Zlib_jll.libz_path), Cint, (gzFile, Ptr{Cvoid}, Cuint), file, buf, len)
end

function gzfread(buf, size::Csize_t, nitems::Csize_t, file::gzFile)
    ccall((:gzfread, Zlib_jll.libz_path), Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, gzFile), buf, size, nitems, file)
end

function gzwrite(file::gzFile, buf, len::Cuint)
    ccall((:gzwrite, Zlib_jll.libz_path), Cint, (gzFile, Ptr{Cvoid}, Cuint), file, buf, len)
end

function gzfwrite(buf, size::Csize_t, nitems::Csize_t, file::gzFile)
    ccall((:gzfwrite, Zlib_jll.libz_path), Csize_t, (Ptr{Cvoid}, Csize_t, Csize_t, gzFile), buf, size, nitems, file)
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

function gzerror(file::gzFile, errnum)
    ccall((:gzerror, Zlib_jll.libz_path), Ptr{Cchar}, (gzFile, Ptr{Cint}), file, errnum)
end

function gzgetc_(file::gzFile)
    ccall((:gzgetc_, Zlib_jll.libz_path), Cint, (gzFile,), file)
end

function zError(arg1::Cint)
    ccall((:zError, Zlib_jll.libz_path), Ptr{Cchar}, (Cint,), arg1)
end

# NOTE: must be a String, not the Ptr that zlibVersion() returns. A const is
# evaluated during precompilation and serialized into the cache file, so a
# stored pointer refers to the *precompiling* process's address space and
# dereferencing it in a later session segfaults.
const zlib_version = unsafe_string(zlibVersion())

# Z_* constants
const Z_OK = Cint(0)
const Z_STREAM_END = Cint(1)
const Z_NEED_DICT = Cint(2)
const Z_ERRNO = Cint(-1)
const Z_STREAM_ERROR = Cint(-2)
const Z_DATA_ERROR = Cint(-3)
const Z_MEM_ERROR = Cint(-4)
const Z_BUF_ERROR = Cint(-5)
const Z_VERSION_ERROR = Cint(-6)

const Z_NO_COMPRESSION = Cint(0)
const Z_BEST_SPEED = Cint(1)
const Z_BEST_COMPRESSION = Cint(9)
const Z_DEFAULT_COMPRESSION = Cint(-1)

const Z_FILTERED = Cint(1)
const Z_HUFFMAN_ONLY = Cint(2)
const Z_RLE = Cint(3)
const Z_FIXED = Cint(4)
const Z_DEFAULT_STRATEGY = Cint(0)

const Z_SYNC_FLUSH = Cint(2)

end # module
