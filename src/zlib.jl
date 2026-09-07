# Load zlib and zlib-ng wrappers
include("lib/zlib.jl")
include("lib/zlibng.jl")

using .Zlib_h
using .Zlib_h: Z_OK, Z_STREAM_END, Z_NEED_DICT, Z_ERRNO, Z_STREAM_ERROR,
               Z_DATA_ERROR, Z_MEM_ERROR, Z_BUF_ERROR, Z_VERSION_ERROR,
               Z_NO_COMPRESSION, Z_BEST_SPEED, Z_BEST_COMPRESSION, Z_DEFAULT_COMPRESSION,
               Z_FILTERED, Z_HUFFMAN_ONLY, Z_RLE, Z_FIXED, Z_DEFAULT_STRATEGY,
               Z_SYNC_FLUSH
using .ZlibNG_h

# Version strings are normally "1.2.13", but a build may append a
# non-numeric component (zlib-ng's zlib-compat mode reports "1.3.1.zlib-ng"),
# so keep only the leading numeric parts.
function _version_tuple(ver::AbstractString)
    parts = Int[]
    for c in split(ver, '.')
        n = tryparse(Int, c)
        n === nothing && break
        push!(parts, n)
    end
    tuple(parts...)
end

"""
    GZLIB_VERSION

Version string of the zlib library in use, e.g. `"1.2.13"`.

This describes the [`ZLIB`](@ref) backend only. For the version behind the
default zlib-ng backend see [`GZLIBNG_VERSION`](@ref), or use
[`libversion`](@ref) to ask a particular backend or stream.
"""
const GZLIB_VERSION = Zlib_h.zlib_version

"""
    GZLIBNG_VERSION

Version string of the zlib-ng library in use, e.g. `"2.3.3"`.

zlib-ng carries its own version series, unrelated to zlib's; the default
[`ZLIBNG`](@ref) backend is the one this describes.
"""
const GZLIBNG_VERSION = unsafe_string(ZlibNG_h.zlibng_version())

"""
    ZLIB_VERSION

Version of the zlib library as a tuple of integers, e.g. `(1, 2, 13)`,
for comparisons such as `ZLIB_VERSION >= (1, 2, 4)`.
"""
const ZLIB_VERSION = _version_tuple(GZLIB_VERSION)

"""
    ZLIBNG_VERSION

Version of the zlib-ng library as a tuple of integers, e.g. `(2, 3, 3)`.
"""
const ZLIBNG_VERSION = _version_tuple(GZLIBNG_VERSION)

# Constants for use with gzbuffer
const Z_DEFAULT_BUFSIZE = 8192
const Z_BIG_BUFSIZE = 131072

"""
    ZFileOffset

Integer type used for file offsets in zlib, determined from the library's compile flags.
"""
const ZFileOffset = Zlib_h.z_off_t

"""
    ZError <: Exception

zlib error, containing an error code and message string.
"""
struct ZError <: Exception
    err::Cint
    err_str::String
end

# --- Backend abstraction ---

"""
    GZBackend

Abstract type for gzip compression backends. Concrete subtypes are
[`ZlibBackend`](@ref) and [`ZlibNGBackend`](@ref).
"""
abstract type GZBackend end

"""
    ZlibBackend <: GZBackend

Standard zlib backend (Zlib_jll). Use `backend=GZip.ZLIB` to select.
"""
struct ZlibBackend <: GZBackend end

"""
    ZlibNGBackend <: GZBackend

Default backend using zlib-ng (ZlibNG_jll), a high-performance fork of zlib.
"""
struct ZlibNGBackend <: GZBackend end

"""
    ZLIB

The standard zlib backend. Pass as `backend=GZip.ZLIB` to `gzopen`/`gzdopen`.
"""
const ZLIB = ZlibBackend()

"""
    ZLIBNG

The default zlib-ng backend. Pass as `backend=GZip.ZLIBNG` to `gzopen`/`gzdopen`.
"""
const ZLIBNG = ZlibNGBackend()

"""
    libversion(backend::GZBackend) -> String
    libversion(s::GZipStream) -> String

Version string of the compression library behind `backend`, or behind the
backend `s` was opened with.

```jldoctest
julia> GZip.libversion(GZip.ZLIBNG) == GZip.GZLIBNG_VERSION
true
```
"""
libversion(::ZlibBackend) = GZLIB_VERSION
libversion(::ZlibNGBackend) = GZLIBNG_VERSION

# Use Ptr{Nothing} as the unified gzFile type to avoid coupling to either wrapper module
const GZFile = Ptr{Nothing}

# --- Dispatched gz functions ---

gz_open(::ZlibBackend, fname, mode) = reinterpret(GZFile, Zlib_h.gzopen(fname, mode))
gz_open(::ZlibNGBackend, fname, mode) = reinterpret(GZFile, ZlibNG_h.zng_gzopen(fname, mode))

gz_dopen(::ZlibBackend, fd::Cint, mode) = reinterpret(GZFile, Zlib_h.gzdopen(fd, mode))
gz_dopen(::ZlibNGBackend, fd::Cint, mode) = reinterpret(GZFile, ZlibNG_h.zng_gzdopen(fd, mode))

gz_buffer(::ZlibBackend, file::GZFile, size) = Zlib_h.gzbuffer(reinterpret(Zlib_h.gzFile, file), Cuint(size))
gz_buffer(::ZlibNGBackend, file::GZFile, size) = ZlibNG_h.zng_gzbuffer(reinterpret(ZlibNG_h.gzFile, file), UInt32(size))

gz_read(::ZlibBackend, file::GZFile, buf, len) = Zlib_h.gzread(reinterpret(Zlib_h.gzFile, file), buf, Cuint(len))
gz_read(::ZlibNGBackend, file::GZFile, buf, len) = ZlibNG_h.zng_gzread(reinterpret(ZlibNG_h.gzFile, file), buf, UInt32(len))

gz_fread(::ZlibBackend, buf, size, nitems, file::GZFile) = Zlib_h.gzfread(buf, Csize_t(size), Csize_t(nitems), reinterpret(Zlib_h.gzFile, file))
gz_fread(::ZlibNGBackend, buf, size, nitems, file::GZFile) = ZlibNG_h.zng_gzfread(buf, Csize_t(size), Csize_t(nitems), reinterpret(ZlibNG_h.gzFile, file))

gz_write(::ZlibBackend, file::GZFile, buf, len) = Zlib_h.gzwrite(reinterpret(Zlib_h.gzFile, file), buf, Cuint(len))
gz_write(::ZlibNGBackend, file::GZFile, buf, len) = ZlibNG_h.zng_gzwrite(reinterpret(ZlibNG_h.gzFile, file), buf, UInt32(len))

gz_fwrite(::ZlibBackend, buf, size, nitems, file::GZFile) = Zlib_h.gzfwrite(buf, Csize_t(size), Csize_t(nitems), reinterpret(Zlib_h.gzFile, file))
gz_fwrite(::ZlibNGBackend, buf, size, nitems, file::GZFile) = ZlibNG_h.zng_gzfwrite(buf, Csize_t(size), Csize_t(nitems), reinterpret(ZlibNG_h.gzFile, file))

gz_gets(::ZlibBackend, file::GZFile, buf, len) = Zlib_h.gzgets(reinterpret(Zlib_h.gzFile, file), buf, Cint(len))
gz_gets(::ZlibNGBackend, file::GZFile, buf, len) = ZlibNG_h.zng_gzgets(reinterpret(ZlibNG_h.gzFile, file), buf, Int32(len))

gz_putc(::ZlibBackend, file::GZFile, c) = Zlib_h.gzputc(reinterpret(Zlib_h.gzFile, file), Cint(c))
gz_putc(::ZlibNGBackend, file::GZFile, c) = ZlibNG_h.zng_gzputc(reinterpret(ZlibNG_h.gzFile, file), Int32(c))

gz_ungetc(::ZlibBackend, c, file::GZFile) = Zlib_h.gzungetc(Cint(c), reinterpret(Zlib_h.gzFile, file))
gz_ungetc(::ZlibNGBackend, c, file::GZFile) = ZlibNG_h.zng_gzungetc(Int32(c), reinterpret(ZlibNG_h.gzFile, file))

# gzgetc_ exists in zlib but not zlib-ng; for zlib-ng, use gzread of 1 byte
gz_getc(::ZlibBackend, file::GZFile) = Zlib_h.gzgetc_(reinterpret(Zlib_h.gzFile, file))
function gz_getc(::ZlibNGBackend, file::GZFile)
    buf = Ref{UInt8}(0)
    ret = ZlibNG_h.zng_gzread(reinterpret(ZlibNG_h.gzFile, file), buf, UInt32(1))
    ret == 1 ? Cint(buf[]) : Cint(-1)
end

gz_flush(::ZlibBackend, file::GZFile, fl) = Zlib_h.gzflush(reinterpret(Zlib_h.gzFile, file), Cint(fl))
gz_flush(::ZlibNGBackend, file::GZFile, fl) = ZlibNG_h.zng_gzflush(reinterpret(ZlibNG_h.gzFile, file), Int32(fl))

gz_seek(::ZlibBackend, file::GZFile, offset, whence) = Zlib_h.gzseek(reinterpret(Zlib_h.gzFile, file), Zlib_h.z_off_t(offset), Cint(whence))
gz_seek(::ZlibNGBackend, file::GZFile, offset, whence) = ZlibNG_h.zng_gzseek(reinterpret(ZlibNG_h.gzFile, file), ZlibNG_h.z_off64_t(offset), Cint(whence))

gz_rewind(::ZlibBackend, file::GZFile) = Zlib_h.gzrewind(reinterpret(Zlib_h.gzFile, file))
gz_rewind(::ZlibNGBackend, file::GZFile) = ZlibNG_h.zng_gzrewind(reinterpret(ZlibNG_h.gzFile, file))

gz_tell(::ZlibBackend, file::GZFile) = Zlib_h.gztell(reinterpret(Zlib_h.gzFile, file))
gz_tell(::ZlibNGBackend, file::GZFile) = ZlibNG_h.zng_gztell(reinterpret(ZlibNG_h.gzFile, file))

gz_offset(::ZlibBackend, file::GZFile) = Zlib_h.gzoffset(reinterpret(Zlib_h.gzFile, file))
gz_offset(::ZlibNGBackend, file::GZFile) = ZlibNG_h.zng_gzoffset(reinterpret(ZlibNG_h.gzFile, file))

gz_eof(::ZlibBackend, file::GZFile) = Zlib_h.gzeof(reinterpret(Zlib_h.gzFile, file))
gz_eof(::ZlibNGBackend, file::GZFile) = ZlibNG_h.zng_gzeof(reinterpret(ZlibNG_h.gzFile, file))

gz_direct(::ZlibBackend, file::GZFile) = Zlib_h.gzdirect(reinterpret(Zlib_h.gzFile, file))
gz_direct(::ZlibNGBackend, file::GZFile) = ZlibNG_h.zng_gzdirect(reinterpret(ZlibNG_h.gzFile, file))

gz_close(::ZlibBackend, file::GZFile) = Zlib_h.gzclose(reinterpret(Zlib_h.gzFile, file))
gz_close(::ZlibNGBackend, file::GZFile) = ZlibNG_h.zng_gzclose(reinterpret(ZlibNG_h.gzFile, file))

gz_error(::ZlibBackend, file::GZFile, errnum) = Zlib_h.gzerror(reinterpret(Zlib_h.gzFile, file), errnum)
gz_error(::ZlibNGBackend, file::GZFile, errnum) = ZlibNG_h.zng_gzerror(reinterpret(ZlibNG_h.gzFile, file), errnum)

gz_zerror(::ZlibBackend, e) = unsafe_string(Zlib_h.zError(Cint(e)))
gz_zerror(::ZlibNGBackend, e) = unsafe_string(ZlibNG_h.zng_zError(Int32(e)))
