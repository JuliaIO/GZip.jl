## gzip file io ##

module GZip

using Compat

import Base: show, fd, close, flush, truncate, seek,
             seekend, skip, position, eof, read, readall,
             readline, write, peek

export
  GZipStream,
  GZipBufferedStream,
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
  readall,
  readline,
  write,
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

include("zlib_h.jl")

const GZLIB_VERSION = bytestring(ccall((:zlibVersion, GZip._zlib), Ptr{UInt8}, ()))

# Expected line length for strings
const GZ_LINE_BUFSIZE = 256

# Wrapper around gzFile
type GZipStream <: IO
    name::String
    gz_file::Ptr{Void}
    buf_size::Int

    _closed::Bool

    GZipStream(name::String, gz_file::Ptr{Void}, buf_size::Int) =
        (x = new(name, gz_file, buf_size, false); finalizer(x, close); x)
end
GZipStream(name::String, gz_file::Ptr{Void}) = GZipStream(name, gz_file, Z_DEFAULT_BUFSIZE)

# Wrapper around GZipStream and IOBuffer for buffered I/O
immutable GZipBufferedStream <: IO
    s::GZipStream
    io::IOBuffer

    function GZipBufferedStream(s::GZipStream, io::IOBuffer)
        eof(io) && !eof(s) && read(s, io)
        new(s, io)
    end
end


# gzerror
function gzerror(err::Integer, s::GZipStream)
    e = Int32[err]
    if !s._closed
        msg_p = ccall((:gzerror, _zlib), Ptr{UInt8}, (Ptr{Void}, Ptr{Int32}),
                      s.gz_file, e)
        msg = (msg_p == C_NULL ? "" : bytestring(msg_p))
    else
        msg = "(GZipStream closed)"
    end
    (e[1], msg)
end
gzerror(s::GZipStream) = gzerror(0, s)

type GZError <: Exception
    err::Int32
    err_str::String

    GZError(e::Integer, str::String) = new(@compat(Int32(e)), str)
    GZError(e::Integer, s::GZipStream) = (a = gzerror(e, s); new(a[1], a[2]))
    GZError(s::GZipStream) = (a = gzerror(s); new(a[1], a[2]))
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
gzgetc(s::GZipStream) =
    @test_eof_gzerr(s, ccall((:gzgetc, _zlib), Int32, (Ptr{Void},), s.gz_file), -1)

gzgetc_raw(s::GZipStream) = ccall((:gzgetc, _zlib), Int32, (Ptr{Void},), s.gz_file)

gzungetc(c::Integer, s::GZipStream) =
    @test_eof_gzerr(s, ccall((:gzungetc, _zlib), Int32, (Int32, Ptr{Void}), c, s.gz_file), -1)

gzgets(s::GZipStream, a::Array{UInt8}) =
    @test_eof_gzerr2(s,
                     ccall((:gzgets, _zlib), Ptr{UInt8}, (Ptr{Void}, Ptr{UInt8}, Int32),
                           s.gz_file, a, @compat(Int32(length(a)))),
                     C_NULL)

gzgets(s::GZipStream, p::Ptr{UInt8}, len::Integer) =
    @test_eof_gzerr2(s,
                     ccall((:gzgets, _zlib), Ptr{UInt8}, (Ptr{Void}, Ptr{UInt8}, Int32),
                           s.gz_file, p, @compat(Int32(len))),
                     C_NULL)

gzputc(s::GZipStream, c::Integer) =
    @test_gzerror(s,
                  ccall((:gzputc, _zlib), Int32, (Ptr{Void}, Int32),
                        s.gz_file, @compat(Int32(c))),
                  -1)

gzwrite(s::GZipStream, p::Ptr, len::Integer) =
    len == 0 ? @compat(Int32(0)) :
               @test_gzerror0(s, ccall((:gzwrite, _zlib), Int32, (Ptr{Void}, Ptr{Void}, UInt32),
                                       s.gz_file, p, len))

gzread(s::GZipStream, p::Ptr, len::Integer) =
    @test_gzerror(s,
                  ccall((:gzread, _zlib), Int32, (Ptr{Void}, Ptr{Void}, UInt32),
                        s.gz_file, p, len),
                  -1)

let _zlib_h = Libdl.dlopen(_zlib)
    global gzbuffer, _gzopen, _gzseek, _gztell, _gzrewind, _gzdirect, _gzoffset

    # Doesn't exist in zlib 1.2.3 or earlier
    if Libdl.dlsym_e(_zlib_h, :gzbuffer) != C_NULL
        gzbuffer(gz_file::Ptr, gz_buf_size::Integer) =
           ccall((:gzbuffer, _zlib), Int32, (Ptr{Void}, UInt32), gz_file, gz_buf_size)
    else
        gzbuffer(gz_file::Ptr, gz_buf_size::Integer) = @compat Int32(-1)
    end

    #####

    # Use 64-bit functions if available

    if Libdl.dlsym_e(_zlib_h, :gzopen64) != C_NULL
        const _gzopen = :gzopen64
        const _gzseek = :gzseek64
        const _gztell = :gztell64
        const _gzoffset = :gzoffset64
    else
        const _gzopen = :gzopen
        const _gzseek = :gzseek
        const _gztell = :gztell
        const _gzoffset = :gzoffset
    end
    const _gzrewind = :gzrewind
    const _gzdirect = :gzdirect
end

function gzopen(fname::String, gzmode::String="rb",
    gz_buf_size::Integer=Z_DEFAULT_BUFSIZE; buffered=false)

    # gzmode can contain extra characters specifying
    # * compression level (0-9)
    # * strategy ('f' => filtered data, 'h' -> Huffman-only compression,
    #             'R' -> run-length encoding, 'F' -> fixed code compression)
    #
    # '+' is also not allowed

    #Buffered writes not yet implemented - Ref #23, #32
    if 'w' in gzmode && buffered
        warn("Buffered writes not yet implemented. Turning buffering off.")
        buffered = false
    end

    # For windows, force binary mode; doesn't hurt on unix
    if !('b' in gzmode)
        gzmode *= "b"
    end

    gz_file = ccall((_gzopen, _zlib), Ptr{Void}, (Ptr{UInt8}, Ptr{UInt8}), fname, gzmode)
    if gz_file == C_NULL
        throw(GZError(-1, "gzopen failed"))
    end

    #Set internal buffer size
    if gz_buf_size != Z_DEFAULT_BUFSIZE
        if gzbuffer(gz_file, gz_buf_size) == -1
            # Generally a non-fatal error, although it shouldn't happen here
            gz_buf_size = Z_DEFAULT_BUFSIZE
        end
    end

    #Return buffered stream if requested and supported
    io = GZipStream(fname, gz_file, gz_buf_size)
    if buffered
        buf = IOBuffer(gz_buf_size)
        GZipBufferedStream(io, buf)
    else
        io
    end
end
open(args...; kwargs...) = gzopen(args...; kwargs...)

function gzopen(f::Function, args...; kwargs...)
    io = gzopen(args...; kwargs...)
    try f(io)
    finally close(io)
    end
end

function gzdopen(fname::String, fd::Integer, gzmode::String="rb",
    gz_buf_size::Integer=Z_DEFAULT_BUFSIZE; buffered=false)

    #Buffered writes not yet implemented - Ref #23, #32
    if 'w' in gzmode && buffered
        warn("Buffered writes not yet implemented. Turning buffering off.")
        buffered = false
    end

    if !('b' in gzmode)
        gzmode *= "b"
    end

    # Duplicate the file descriptor, since we have no way to tell gzclose()
    # not to close the original fd
    dup_fd = ccall(:dup, Int32, (Int32,), fd)

    gz_file = ccall((:gzdopen, _zlib), Ptr{Void}, (Int32, Ptr{UInt8}), dup_fd, gzmode)
    if gz_file == C_NULL
        throw(GZError(-1, "gzdopen failed"))
    end

    #Set default buffer size
    if gz_buf_size != Z_DEFAULT_BUFSIZE
        if gzbuffer(gz_file, gz_buf_size) == -1
            # Generally a non-fatal error, although it shouldn't happen here
            gz_buf_size = Z_DEFAULT_BUFSIZE
        end
    end

    #Return buffered stream if requested and supported
    io = GZipStream(fname, gz_file, gz_buf_size)
    if buffered
        buf = IOBuffer(gz_buf_size)
        GZipBufferedStream(io, buf)
    else
        io
    end
end
gzdopen(fd::Integer, gzmode::String, gz_buf_size::Integer) = gzdopen(string("<fd ",fd,">"), fd, gzmode, gz_buf_size)
gzdopen(fd::Integer, gz_buf_size::Integer) = gzdopen(fd, "rb", gz_buf_size)
gzdopen(fd::Integer, gzmode::String) = gzdopen(fd, gzmode, Z_DEFAULT_BUFSIZE)
gzdopen(fd::Integer) = gzdopen(fd, "rb", Z_DEFAULT_BUFSIZE)
gzdopen(s::IOStream, args...) = gzdopen(fd(s), args...)

fd(s::GZipStream) = throw(ArgumentError("fd is not supported for GZipStreams"))

function close(s::GZipStream)

    # The garbage collector needs to be temporarily disabled because of a possible
    # race condition if it runs between testing and setting s._closed

    gc_enable(false)
    if s._closed
        gc_enable(true)
        return Z_STREAM_ERROR
    end
    s._closed = true
    gc_enable(true)

    s.name *= " (closed)"

    ret = (@test_z_ok ccall((:gzclose, _zlib), Int32, (Ptr{Void},), s.gz_file))

    return ret
end

function close(s::GZipBufferedStream)
    close(s.s)
    close(s.io)
end

flush(s::GZipStream, fl::Integer) =
    @test_z_ok ccall((:gzflush, _zlib), Int32, (Ptr{Void}, Int32), s.gz_file, @compat(Int32(fl)))
flush(s::GZipStream) = flush(s, Z_SYNC_FLUSH)

truncate(s::GZipStream, n::Integer) = throw(MethodError(truncate, (GZipStream, Integer)))

# Note: seeks to byte position within uncompressed data stream
function seek(s::GZipStream, n::Integer)
    # Note: band-aid to avoid a bug occurring on uncompressed files under Windows
    @windows_only if (ccall((_gzdirect, _zlib), Cint, (Ptr{Void},), s.gz_file)) == 1
        ccall((_gzrewind, _zlib), Cint, (Ptr{Void},), s.gz_file)!=-1 ||
            error("seek (gzseek) failed")
    end
    ccall((_gzseek, _zlib), ZFileOffset, (Ptr{Void}, ZFileOffset, Int32),
           s.gz_file, n, SEEK_SET)!=-1 || # Mimick behavior of seek(s::IOStream, n)
        error("seek (gzseek) failed")
end

# Note: skips bytes within uncompressed data stream
skip(s::GZipStream, n::Integer) =
    (ccall((_gzseek, _zlib), ZFileOffset, (Ptr{Void}, ZFileOffset, Int32),
           s.gz_file, n, SEEK_CUR)!=-1 ||
     error("skip (gzseek) failed")) # Mimick behavior of skip(s::IOStream, n)

if GZLIB_VERSION > "1.2.3.9"
position(s::GZipStream, raw::Bool=false) = raw ?
    ccall((_gzoffset, _zlib), ZFileOffset, (Ptr{Void},), s.gz_file) :
      ccall((_gztell, _zlib), ZFileOffset, (Ptr{Void},), s.gz_file)
else
position(s::GZipStream, raw::Bool=false) =
      ccall((_gztell, _zlib), ZFileOffset, (Ptr{Void},), s.gz_file)
end
position(s::GZip.GZipBufferedStream, raw::Bool=false) = position(s.s, raw)

eof(s::GZipStream) = @compat Bool(ccall((:gzeof, _zlib), Int32, (Ptr{Void},), s.gz_file))
eof(s::GZipBufferedStream) = eof(s.io)

function peek(s::GZipStream)
    c = gzgetc_raw(s)
    if c != -1
        gzungetc(c, s)
    end
    c
end

# Mimics read(s::IOStream, a::Array{T})
function read{T}(s::GZipStream, a::Array{T})
    if isbits(T)
        nb = length(a)*sizeof(T)
        # Note: this will overflow and succeed without warning if nb > 4GB
        ret = ccall((:gzread, _zlib), Int32,
                    (Ptr{Void}, Ptr{Void}, UInt32), s.gz_file, a, nb)
        if ret == -1
            throw(GZError(s))
        end
        if ret < nb
            throw(EOFError())  # TODO: Do we have/need a way to read without throwing an error near the end of the file?
        end
        peek(s) # force eof to be set
        a
    else
        invoke(read, (IO, Array), s, a)
    end
end

function read(s::GZipStream, ::Type{UInt8})
    ret = gzgetc(s)
    if ret == -1
        throw(GZError(s))
    end
    peek(s) # force eof to be set
    @compat UInt8(ret)
end

function read(s::GZipBufferedStream, ::Type{UInt8})
    c = read(s.io, UInt8)

    #Check if we should reload buffer
    eof(s.io) && !eof(s.s) && read(s.s, s.io)

    c
end

#Like read(::GZipStream), but don't complain if returned data is smaller than
#buffer
function read(s::GZipStream, io::IOBuffer)
    ret = ccall((:gzread, _zlib), Int32, (Ptr{Void}, Ptr{Void},
        UInt32), s.gz_file, io.data, s.buf_size)

    ret==-1 && throw(GZError(s))

    io.size = ret #set buffer size to number of bytes returned
    peek(s) # force eof to be set
    seek(io, 0)
end

# For this function, it's really unfortunate that zlib is
# not integrated with ios
function readall(s::GZipStream, bufsize::Int)
    buf = Array(UInt8, bufsize)
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
            return bytestring(buf)
        end
        len += ret
        # Grow the buffer so that bufsize bytes will fit
        resize!(buf, bufsize+len)
    end
end
readall(s::GZipStream) = readall(s, Z_BIG_BUFSIZE)

function readline(s::GZipStream)
    buf = Array(UInt8, GZ_LINE_BUFSIZE)
    pos = 1

    if gzgets(s, buf) == C_NULL      # Throws an exception on error
        return ""
    end

    while(true)
        # since gzgets didn't return C_NULL, there must be a \0 in the buffer
        eos = search(buf, '\0', pos)
        if eos == 1 || buf[eos-1] == '\n'
            return bytestring(resize!(buf, eos-1))
        end

        # If we're at the end of the file, return the string
        if eof(s)  return bytestring(resize!(buf, eos-1))  end

        # Otherwise, append to the end of the previous buffer

        # Grow the buffer so that there's room for GZ_LINE_BUFSIZE chars
        add_len = GZ_LINE_BUFSIZE - (length(buf)-eos+1)
        resize!(buf, add_len+length(buf))
        pos = eos

        # Read in the next chunk
        if gzgets(s, pointer(buf)+pos-1, GZ_LINE_BUFSIZE) == C_NULL
            # eof(s); remove extra buffer space
            return bytestring(resize!(buf, length(buf)-add_len))
        end
    end
end

write(s::GZipStream, b::UInt8) = gzputc(s, b)

function write{T}(s::GZipStream, a::Array{T})
    if isbits(T)
        return gzwrite(s, pointer(a), length(a)*sizeof(T))
    else
        invoke(write, (Any, Array), s, a)
    end
end

write(s::GZipStream, p::Ptr, nb::Integer) = gzwrite(s, p, nb)

function write{T,N}(s::GZipStream, a::SubArray{T,N,Array})
    if !isbits(T) || stride(a,1)!=1
        return invoke(write, (Any, AbstractArray), s, a)
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
