## gzip file io ##AA
module GZip
using Libdl
using Base.Libc
import Base: show, fd, close, flush, truncate, seek,
             seekend, skip, position, eof, read,
             readline, write, unsafe_write, peek

# Load one of the platform-specific Clang.jl generated wrappers
const IS_LIBC_MUSL = occursin("musl", Base.BUILD_TRIPLET)
if Sys.isapple() && Sys.ARCH === :aarch64
    include("lib/aarch64-apple-darwin20.jl")
elseif Sys.islinux() && Sys.ARCH === :aarch64 && !IS_LIBC_MUSL
    include("lib/aarch64-linux-gnu.jl")
elseif Sys.islinux() && Sys.ARCH === :aarch64 && IS_LIBC_MUSL
    include("lib/aarch64-linux-musl.jl")
elseif Sys.islinux() && startswith(string(Sys.ARCH), "arm") && !IS_LIBC_MUSL
    include("lib/armv7l-linux-gnueabihf.jl")
elseif Sys.islinux() && startswith(string(Sys.ARCH), "arm") && IS_LIBC_MUSL
    include("lib/armv7l-linux-musleabihf.jl")
elseif Sys.islinux() && Sys.ARCH === :i686 && !IS_LIBC_MUSL
    include("lib/i686-linux-gnu.jl")
elseif Sys.islinux() && Sys.ARCH === :i686 && IS_LIBC_MUSL
    include("lib/i686-linux-musl.jl")
elseif Sys.iswindows() && Sys.ARCH === :i686
    include("lib/i686-w64-mingw32.jl")
elseif Sys.islinux() && Sys.ARCH === :powerpc64le
    include("lib/powerpc64le-linux-gnu.jl")
elseif Sys.isapple() && Sys.ARCH === :x86_64
    include("lib/x86_64-apple-darwin14.jl")
elseif Sys.islinux() && Sys.ARCH === :x86_64 && !IS_LIBC_MUSL
    include("lib/x86_64-linux-gnu.jl")
elseif Sys.islinux() && Sys.ARCH === :x86_64 && IS_LIBC_MUSL
    include("lib/x86_64-linux-musl.jl")
elseif Sys.isbsd() && !Sys.isapple()
    include("lib/x86_64-unknown-freebsd.jl")
elseif Sys.iswindows() && Sys.ARCH === :x86_64
    include("lib/x86_64-w64-mingw32.jl")
else
    error("Unknown platform: $(Base.BUILD_TRIPLET)")
end

using .Zlib_h

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

const GZLIB_VERSION = unsafe_string(Zlib_h.zlib_version)
const ZLIB_VERSION  = tuple([parse(Int, c) for c in split(GZLIB_VERSION, '.')]...)

# Expected line length for strings
const GZ_LINE_BUFSIZE = 256

# Constants for use with gzbuffer
const Z_DEFAULT_BUFSIZE = 8192
const Z_BIG_BUFSIZE = 131072

# Constants for use with gzseek
const SEEK_SET =  Cint(0)
const SEEK_CUR =  Cint(1)

# Create ZFileOffset alias
# Use 64bit if the *64 functions are available or zlib is compiles with 64bit
# file offset.

# Get compile-time option flags
const zlib_compile_flags = Zlib_h.zlibCompileFlags()
const z_off_t_sz = 2 << ((zlib_compile_flags >> 6) & UInt(3))
if z_off_t_sz == 8 || (!Sys.iswindows() && Libdl.dlsym_e(Zlib_jll.libz_handle, :gzopen64) != C_NULL)
    const ZFileOffset = Int64
elseif z_off_t_sz == 4
    const ZFileOffset = Int32
else
    error("Can't figure out what to do with ZFileOffset. sizeof(z_off_t) = ", z_off_t_sz)
end

# Wrapper around gzFile
mutable struct GZipStream <: IO
    name::AbstractString
    gz_file::Zlib_h.gzFile
    buf_size::Int

    _closed::Bool

    function GZipStream(name::AbstractString, gz_file::Zlib_h.gzFile, buf_size::Int)
        x = new(name, gz_file, buf_size, false)
        finalizer(close, x)
        x
    end
end
GZipStream(name::AbstractString, gz_file::Zlib_h.gzFile) = GZipStream(name, gz_file, Z_DEFAULT_BUFSIZE)

# gzerror
function gzerror(err::Integer, s::GZipStream)
    e = Cint[err]
    if !s._closed
        msg_p = Zlib_h.gzerror(s.gz_file, e)
        msg = (msg_p == C_NULL ? "" : unsafe_string(msg_p))
    else
        msg = "(GZipStream closed)"
    end
    (e[1], msg)
end
gzerror(s::GZipStream) = gzerror(0, s)

mutable struct GZError <: Exception
    err::Int32
    err_str::AbstractString

    GZError(e::Integer, str::AbstractString) = new(Int32(e), str)
    GZError(e::Integer, s::GZipStream) = (a = gzerror(e, s); new(a[1], a[2]))
    GZError(s::GZipStream) = (a = gzerror(s); new(a[1], a[2]))
end

# Zlib errors as Exceptions
zerror(e::Integer) = unsafe_string(zError(e))
mutable struct ZError <: Exception
    err::Cint
    err_str::AbstractString

    ZError(e::Integer) = (e == Z_ERRNO ? new(e, strerror()) : new(e, zerror(e)))
end

# show
show(io::IO, s::GZipStream) = print(io, "GZipStream(", s.name, ")")

macro test_eof_gzerr(s, cc, val)
    quote
        if $(esc(s))._closed throw(EOFError()) end
        ret = $(esc(cc))
        if ret == $(esc(val))
            if eof($(esc(s)))  throw(EOFError())  else  throw(GZError($(esc(s))))  end
        end
        ret
    end
end

macro test_eof_gzerr2(s, cc, val)
    quote
        if $(esc(s))._closed throw(EOFError()) end
        ret = $(esc(cc))
        if ret == $(esc(val)) && !eof($(esc(s))) throw(GZError($(esc(s)))) end
        ret
    end
end

macro test_gzerror(s, cc, val)
    quote
        if $(esc(s))._closed throw(EOFError()) end
        ret = $(esc(cc))
        if ret == $(esc(val)) throw(GZError(ret, $(esc(s)))) end
        ret
    end
end

macro test_gzerror0(s, cc)
    quote
        if $(esc(s))._closed throw(EOFError()) end
        ret = $(esc(cc))
        if ret <= 0 throw(GZError(ret, $(esc(s)))) end
        ret
    end
end

macro test_z_ok(cc)
    quote
        ret = $(esc(cc))
        if (ret != Z_OK) throw(ZError(ret)) end
        ret
    end
end

# Easy access to gz reading/writing functions (Internal)
gzgetc(s::GZipStream) = @test_eof_gzerr(s, Zlib_h.gzgetc_(s.gz_file), -1)

gzgetc_raw(s::GZipStream) = Zlib_h.gzgetc_(s.gz_file)

gzungetc(c::Integer, s::GZipStream) = @test_eof_gzerr(s, Zlib_h.gzungetc(c, s.gz_file), -1)

gzgets(s::GZipStream, a::Array{UInt8}) =
    @test_eof_gzerr2(s, Zlib_h.gzgets(s.gz_file, a, Cint(length(a))), C_NULL)

gzgets(s::GZipStream, p::Ptr{UInt8}, len::Integer) =
    @test_eof_gzerr2(s, Zlib_h.gzgets(s.gz_file, p, Cint(len)), C_NULL)

gzputc(s::GZipStream, c::Integer) = @test_gzerror(s, Zlib_h.gzputc(s.gz_file, Cint(c)), -1)

gzwrite(s::GZipStream, p::Ptr, len::Integer) =
    len == 0 ? Cint(0) : @test_gzerror0(s, Zlib_h.gzwrite(s.gz_file, reinterpret(Ptr{Cvoid}, p), Cuint(len)))

gzread(s::GZipStream, p::Ptr, len::Integer) =
    @test_gzerror(s, Zlib_h.gzread(s.gz_file, reinterpret(Ptr{Cvoid}, p), Cuint(len)), -1)

global gzbuffer, _gzopen, _gzseek, _gztell, _gzoffset

# Doesn't exist in zlib 1.2.3 or earlier
if Libdl.dlsym_e(Zlib_jll.libz_handle, :gzbuffer) != C_NULL
    gzbuffer(gz_file::Zlib_h.gzFile, gz_buf_size::Integer) = Zlib_h.gzbuffer(gz_file, gz_buf_size)
else
    gzbuffer(gz_file::Zlib_h.gzFile, gz_buf_size::Integer) = Cint(-1)
end

#####

# Use 64-bit functions if available

if Libdl.dlsym_e(Zlib_jll.libz_handle, :gzopen64) != C_NULL && (z_off_t_sz == 8 || !Sys.iswindows())
    const _gzopen = Zlib_h.gzopen64
    const _gzseek = Zlib_h.gzseek64
    const _gztell = Zlib_h.gztell64
    const _gzoffset = Zlib_h.gzoffset64
else
    const _gzopen = Zlib_h.gzopen
    const _gzseek = Zlib_h.gzseek
    const _gztell = Zlib_h.gztell
    const _gzoffset = Zlib_h.gzoffset
end

function gzopen(fname::AbstractString, gzmode::AbstractString, gz_buf_size::Integer)
    # gzmode can contain extra characters specifying
    # * compression level (0-9)
    # * strategy ('f' => filtered data, 'h' -> Huffman-only compression,
    #             'R' -> run-length encoding, 'F' -> fixed code compression)
    #
    # '+' is also not allowed

    # For windows, force binary mode; doesn't hurt on unix
    if !('b' in gzmode)
        gzmode *= "b"
    end

    gz_file = _gzopen(fname, gzmode)
    if gz_file == C_NULL
        errno = unsafe_load(cglobal((:errno, :libc), Cint))
        throw(SystemError("$(fname)", errno))
    end
    if gz_buf_size != Z_DEFAULT_BUFSIZE
        if gzbuffer(gz_file, gz_buf_size) == -1
            # Generally a non-fatal error, although it shouldn't happen here
            gz_buf_size = Z_DEFAULT_BUFSIZE
        end
    end
    s = GZipStream(fname, gz_file, gz_buf_size)
    peek(s) # Set EOF-bit for empty files
    return s
end
gzopen(fname::AbstractString, gzmode::AbstractString) = gzopen(fname, gzmode, Z_DEFAULT_BUFSIZE)
gzopen(fname::AbstractString) = gzopen(fname, "rb", Z_DEFAULT_BUFSIZE)
open(args...) = gzopen(args...)

function gzopen(f::Function, args...)
    io = gzopen(args...)
    try f(io)
    finally close(io)
    end
end

function gzdopen(name::AbstractString, fd::Integer, gzmode::AbstractString, gz_buf_size::Integer)
    if !('b' in gzmode)
        gzmode *= "b"
    end

    # Duplicate the file descriptor, since we have no way to tell gzclose()
    # not to close the original fd
    dup_fd = Libc.dup(Libc.RawFD(fd))

    gz_file = Zlib_h.gzdopen(reinterpret(Cint, dup_fd), gzmode)
    if gz_file == C_NULL
        errno = unsafe_load(cglobal((:errno, :libc), Cint))
        throw(SystemError("$(name)", errno))
    end
    if gz_buf_size != Z_DEFAULT_BUFSIZE
        if gzbuffer(gz_file, gz_buf_size) == -1
            # Generally a non-fatal error, although it shouldn't happen here
            gz_buf_size = Z_DEFAULT_BUFSIZE
        end
    end
    s = GZipStream(name, gz_file, gz_buf_size)
    peek(s) # Set EOF-bit for empty files
    return s
end
gzdopen(fd::Integer, gzmode::AbstractString, gz_buf_size::Integer) = gzdopen(string("<fd ",fd,">"), fd, gzmode, gz_buf_size)
gzdopen(fd::Integer, gz_buf_size::Integer) = gzdopen(fd, "rb", gz_buf_size)
gzdopen(fd::Integer, gzmode::AbstractString) = gzdopen(fd, gzmode, Z_DEFAULT_BUFSIZE)
gzdopen(fd::Integer) = gzdopen(fd, "rb", Z_DEFAULT_BUFSIZE)
gzdopen(s::IOStream, args...) = gzdopen(fd(s), args...)


fd(s::GZipStream) = error("fd is not supported for GZipStreams")

function close(s::GZipStream)
    if s._closed
        return Z_STREAM_ERROR
    end
    s._closed = true

    s.name *= " (closed)"

    ret = (@test_z_ok Zlib_h.gzclose(s.gz_file))

    return ret
end

flush(s::GZipStream, fl::Integer) =
    @test_z_ok Zlib_h.gzflush(s.gz_file, Cint(fl))
flush(s::GZipStream) = flush(s, Z_SYNC_FLUSH)

truncate(s::GZipStream, n::Integer) = throw(MethodError(truncate, (GZipStream, Integer)))

# Note: seeks to byte position within uncompressed data stream
function seek(s::GZipStream, n::Integer)
    # Note: band-aid to avoid a bug occurring on uncompressed files under Windows
    @static if Sys.iswindows()
        if Zlib_h.gzdirect(s.gz_file) ==  1
            Zlib_h.gzrewind(s.gz_file) != -1 || error("seek (gzseek) failed")
        end
    end
    # Mimic behavior of seek(s::IOStream, n)
    _gzseek(s.gz_file, Clong(n), SEEK_SET) != -1 || error("seek (gzseek) failed")
end

# Note: skips bytes within uncompressed data stream
# Mimic behavior of skip(s::IOStream, n)
skip(s::GZipStream, n::Integer) =
    _gzseek(s.gz_file, Clong(n), SEEK_CUR) != -1 || error("skip (gzseek) failed")

if GZLIB_VERSION > "1.2.3.9"
    position(s::GZipStream, raw::Bool=false) = raw ? _gzoffset(s.gz_file) : _gztell(s.gz_file)
else
    position(s::GZipStream, raw::Bool=false) = _gztell(s.gz_file)
end

eof(s::GZipStream) = Bool(Zlib_h.gzeof(s.gz_file))

function peek(s::GZipStream)
    c = gzgetc_raw(s)
    if c != -1
        gzungetc(c, s)
    end
    c
end

# Mimics read(s::IOStream, a::Array{T})
function read(s::GZipStream, a::Array{T}) where {T}
    if isbitstype(T)
        nb = length(a)*sizeof(T)
        # Note: this will overflow and succeed without warning if nb > 4GB
        ret = Zlib_h.gzread(s.gz_file, reinterpret(Ptr{Cvoid}, pointer(a)), Cuint(nb))
        if ret == -1
            throw(GZError(s))
        end
        if ret < nb
            throw(EOFError())  # TODO: Do we have/need a way to read without throwing an error near the end of the file?
        end
        peek(s) # force eof to be set
        a
    else
        invoke(read!, Tuple{IO,Array}, s, a)
    end
end

function read(s::GZipStream, ::Type{UInt8})
    ret = gzgetc(s)
    if ret == -1
        throw(GZError(s))
    end
    peek(s) # force eof to be set
    UInt8(ret)
end


# For this function, it's really unfortunate that zlib is
# not integrated with ios
function read(s::GZipStream, ::Type{String}; bufsize::Int = Z_BIG_BUFSIZE)
    buf = Array{UInt8}(undef, bufsize)
    len = 0
    while true
        ret = gzread(s, pointer(buf)+len, bufsize)
        if ret == 0
            # check error status to make sure stream was not truncated
            # (we won't normally get an error until the close, because it's
            # possible that the file is still being written to.)

            ## *** Disabled, to allow the function to return the buffer ***
            ## *** Truncation error will be generated on gzclose... ***

            #(err, msg) = gzerror(s)
            #if err != Z_OK
            #    throw(GZError(err, msg))
            #end

            # Resize buffer to exact length
            if length(buf) > len
                resize!(buf, len)
            end
            return String(copy(buf))
        end
        len += ret
        # Grow the buffer so that bufsize bytes will fit
        resize!(buf, bufsize+len)
    end
end

function readline(s::GZipStream)
    buf = Array{UInt8}(undef, GZ_LINE_BUFSIZE)
    pos = 1

    if gzgets(s, buf) == C_NULL      # Throws an exception on error
        return ""
    end

    while(true)
        # since gzgets didn't return C_NULL, there must be a \0 in the buffer
        # eos = search(buf, '\0', pos)
        eos = findnext(x->x==UInt8('\0'), buf, pos)::Int
        # @assert eos ≢ nothing
        if eos == 1 || buf[eos-1] == UInt8('\n')
            return String(copy(resize!(buf, eos-1)))
        end

        # If we're at the end of the file, return the string
        if eof(s)
            return String(copy(resize!(buf, eos-1)))
        end

        # Otherwise, append to the end of the previous buffer

        # Grow the buffer so that there's room for GZ_LINE_BUFSIZE chars
        add_len = GZ_LINE_BUFSIZE - (length(buf)-eos+1)
        resize!(buf, add_len+length(buf))
        pos = eos

        # Read in the next chunk
        if gzgets(s, pointer(buf)+pos-1, GZ_LINE_BUFSIZE) == C_NULL
            # eof(s); remove extra buffer space
            return String(copy(resize!(buf, length(buf)-add_len)))
        end
    end
end

write(s::GZipStream, b::UInt8) = gzputc(s, b)
write(s::GZipStream, a::Array{UInt8}) = gzwrite(s, pointer(a), sizeof(a))
unsafe_write(s::GZipStream, p::Ptr{UInt8}, nb::UInt) = gzwrite(s, p, nb)

function write(s::GZipStream, a::SubArray{T,N,Array}) where {T,N}
    if !isbitstype(T) || stride(a,1)!=1
        return invoke(write, Tuple{Any,AbstractArray}, s, a)
    end
    colsz = size(a,1)*sizeof(T)
    if N==1
        write(s, pointer(a, 1), colsz)
    else
        cartesian_map((idxs...)->write(s, pointer(a, idxs), colsz),
                      tuple(1, size(a)[2:end]...))
    end
end

end # module GZip
