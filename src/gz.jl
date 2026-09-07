# Expected line length for strings
const GZ_LINE_BUFSIZE = 256

# Copy n bytes out of a reusable scratch buffer into a String (one allocation)
_str(buf::Vector{UInt8}, n::Integer) = n <= 0 ? "" : GC.@preserve buf unsafe_string(pointer(buf), n)

# Constants for use with gzseek
const SEEK_SET =  Cint(0)
const SEEK_CUR =  Cint(1)

# Wrapper around gzFile
"""
    GZipStream <: IO

    GZipStream(name, gz_file, [buf_size]; backend=ZLIBNG)

Subtype of `IO` which wraps a gzip stream. Returned by [`gzopen`](@ref) and
[`gzdopen`](@ref). Parameterized by the backend (`ZlibBackend` or `ZlibNGBackend`).
"""
mutable struct GZipStream{B<:GZBackend} <: IO
    name::String
    gz_file::GZFile
    buf_size::Int
    backend::B
    _closed::Bool
    _write::Bool
    _linebuf::Vector{UInt8}   # reusable scratch for readline/readuntil

    function GZipStream(name::AbstractString, gz_file::GZFile, buf_size::Int, backend::B, write::Bool=false) where {B<:GZBackend}
        x = new{B}(String(name), gz_file, buf_size, backend, false, write, UInt8[])
        finalizer(close, x)
        x
    end
end

# gzerror
function gzerror(err::Integer, s::GZipStream)
    e = Ref{Cint}(err)
    if !s._closed
        msg_p = gz_error(s.backend, s.gz_file, e)
        msg = (msg_p == C_NULL ? "" : unsafe_string(msg_p))
    else
        msg = "(GZipStream closed)"
    end
    (e[], msg)
end

# Error code only -- no message string built (hot path)
function _gzerrnum(s::GZipStream)
    s._closed && return Z_STREAM_ERROR
    e = Ref{Cint}(Z_OK)
    gz_error(s.backend, s.gz_file, e)
    e[]
end
gzerror(s::GZipStream) = gzerror(0, s)

"""
    GZError <: Exception

gzip error number and string. Possible error values:

| Error number         | String                                                    |
|:---------------------|:----------------------------------------------------------|
|  `Z_OK`              |  No error                                                 |
|  `Z_ERRNO`           |  Filesystem error (consult `errno()`)                     |
|  `Z_STREAM_ERROR`    |  Inconsistent stream state                                |
|  `Z_DATA_ERROR`      |  Compressed data error                                    |
|  `Z_MEM_ERROR`       |  Out of memory                                            |
|  `Z_BUF_ERROR`       |  Input buffer full/output buffer empty                    |
|  `Z_VERSION_ERROR`   |  zlib library version is incompatible with caller version |
"""
struct GZError <: Exception
    err::Int32
    err_str::String

    GZError(e::Integer, str::AbstractString) = new(Int32(e), String(str))
    GZError(e::Integer, s::GZipStream) = (a = gzerror(e, s); new(a[1], String(a[2])))
    GZError(s::GZipStream) = (a = gzerror(s); new(a[1], String(a[2])))
end

# ZError constructor needs backend for gz_zerror dispatch
ZError(e::Integer, backend::GZBackend=ZLIBNG) = (e == Z_ERRNO ? ZError(e, strerror()) : ZError(e, gz_zerror(backend, e)))

function show(io::IO, s::GZipStream)
    print(io, "GZipStream(", s.name)
    if s._closed
        print(io, " [closed]")
    else
        print(io, s._write ? " [write]" : " [read]")
        backend_name = s.backend isa ZlibNGBackend ? "zlib-ng" : "zlib"
        print(io, " ", backend_name)
    end
    print(io, ")")
end

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

macro test_z_ok(s, cc)
    quote
        ret = $(esc(cc))
        if (ret != Z_OK) throw(ZError(ret, $(esc(s)).backend)) end
        ret
    end
end

"""
    gzgetc(s::GZipStream)

Read a single byte from the stream. Throws `EOFError` at end of file.
"""
gzgetc(s::GZipStream) = @test_eof_gzerr(s, gz_getc(s.backend, s.gz_file), -1)

gzgetc_raw(s::GZipStream) = gz_getc(s.backend, s.gz_file)

"""
    gzungetc(c::Integer, s::GZipStream)

Push a byte back onto the stream for subsequent reading.
"""
gzungetc(c::Integer, s::GZipStream) = @test_eof_gzerr(s, gz_ungetc(s.backend, c, s.gz_file), -1)

"""
    gzgets(s::GZipStream, buf)

Read a line from the stream into `buf`, stopping at newline or end of file.
"""
gzgets(s::GZipStream, a::Array{UInt8}) =
    @test_eof_gzerr2(s, gz_gets(s.backend, s.gz_file, a, Cint(length(a))), C_NULL)

gzgets(s::GZipStream, p::Ptr{UInt8}, len::Integer) =
    @test_eof_gzerr2(s, gz_gets(s.backend, s.gz_file, p, Cint(len)), C_NULL)

"""
    gzputc(s::GZipStream, c::Integer)

Write a single byte to the stream.
"""
gzputc(s::GZipStream, c::Integer) = @test_gzerror(s, gz_putc(s.backend, s.gz_file, Cint(c)), -1)

"""
    gzwrite(s::GZipStream, p::Ptr, len::Integer)

Write `len` bytes from pointer `p` to the stream. Returns the number of bytes written.
Uses `gzfwrite` which supports >4GB writes on 64-bit systems.
"""
function gzwrite(s::GZipStream, p::Ptr, len::Integer)
    s._closed && throw(EOFError())
    len == 0 && return Int(0)
    ret = gz_fwrite(s.backend, reinterpret(Ptr{Cvoid}, p), Csize_t(1), Csize_t(len), s.gz_file)
    ret == 0 && len > 0 && throw(GZError(s))
    Int(ret)
end

"""
    gzread(s::GZipStream, p::Ptr, len::Integer)

Read up to `len` bytes from the stream into the buffer at pointer `p`. Returns the number of bytes read.
Uses `gzfread` which supports >4GB reads on 64-bit systems.
"""
function gzread(s::GZipStream, p::Ptr, len::Integer)
    s._closed && throw(EOFError())
    len == 0 && return Int(0)
    ret = gz_fread(s.backend, reinterpret(Ptr{Cvoid}, p), Csize_t(1), Csize_t(len), s.gz_file)
    # gzfread returns short count on both EOF and error; check gzerror to distinguish
    if ret < len
        err = _gzerrnum(s)
        if err != Z_OK && err != Z_STREAM_END
            throw(GZError(err, s))
        end
    end
    Int(ret)
end

"""
    gzbuffer(backend::GZBackend, gz_file, gz_buf_size::Integer)

Set the internal buffer size for the gzip file. Must be called before any read or write.
"""
gzbuffer(backend::GZBackend, gz_file::GZFile, gz_buf_size::Integer) = gz_buffer(backend, gz_file, gz_buf_size)

#####

"""
    gzopen(fname::AbstractString, [gzmode::AbstractString, buf_size::Integer]; backend=ZLIBNG)::GZipStream

Opens a file with mode (default `"r"`), setting internal buffer size to
buf\\_size (default `Z_DEFAULT_BUFSIZE=8192`), and returns a the file as a
`GZipStream`.

`gzmode` must contain one of:

| mode | Description             |
|:-----|:------------------------|
| r    | read                    |
| w    | write, create, truncate |
| a    | write, create, append   |

In addition, gzmode may also contain

| mode | Description                                        |
|:-----|:---------------------------------------------------|
| x    | create the file exclusively (fails if file exists) |
| 0-9  | compression level                                  |

and/or a compression strategy:

| mode | Description             |
|:-----|:------------------------|
| f    | filtered data            |
| h    | Huffman-only compression |
| R    | run-length encoding      |
| F    | fixed code compression   |

Note that `+` is not allowed in `gzmode`. If an error occurs, `gzopen` throws a [`GZError`](@ref).

Use `backend=GZip.ZLIB` to use the standard zlib backend instead of the default zlib-ng.
"""
function gzopen(fname::AbstractString, gzmode::AbstractString, gz_buf_size::Integer;
                backend::GZBackend=ZLIBNG)
    # For windows, force binary mode; doesn't hurt on unix
    if !('b' in gzmode)
        gzmode *= "b"
    end

    gz_file = gz_open(backend, fname, gzmode)
    if gz_file == C_NULL
        errno = Libc.errno()
        throw(SystemError("$(fname)", errno))
    end
    if gz_buf_size != Z_DEFAULT_BUFSIZE
        if gzbuffer(backend, gz_file, gz_buf_size) == -1
            @warn "gzbuffer failed, using default buffer size" requested=gz_buf_size default=Z_DEFAULT_BUFSIZE
            gz_buf_size = Z_DEFAULT_BUFSIZE
        end
    end
    iswrite = ('w' in gzmode || 'a' in gzmode)
    s = GZipStream(fname, gz_file, gz_buf_size, backend, iswrite)
    iswrite || _peek(s) # Set EOF-bit for empty files (read mode only)
    return s
end
gzopen(fname::AbstractString, gzmode::AbstractString; backend::GZBackend=ZLIBNG) = gzopen(fname, gzmode, Z_DEFAULT_BUFSIZE; backend)
gzopen(fname::AbstractString; backend::GZBackend=ZLIBNG) = gzopen(fname, "rb", Z_DEFAULT_BUFSIZE; backend)

"""
    open(fname::AbstractString, [gzmode, bufsize]; backend=ZLIBNG)::GZipStream

Alias for [`gzopen`](@ref). This is not exported, and must be called using `GZip.open`.
"""
open(args...; kwargs...) = gzopen(args...; kwargs...)

function gzopen(f::Function, args...; kwargs...)
    io = gzopen(args...; kwargs...)
    try f(io)
    finally close(io)
    end
end

"""
    gzdopen(fd, [gzmode, buf_size]; backend=ZLIBNG)

Create a `GZipStream` object from an integer file descriptor.
See [`gzopen`](@ref) for `gzmode` and `buf_size` descriptions.
"""
function gzdopen(name::AbstractString, fd::Integer, gzmode::AbstractString, gz_buf_size::Integer;
                 backend::GZBackend=ZLIBNG)
    if !('b' in gzmode)
        gzmode *= "b"
    end

    # Duplicate the file descriptor, since we have no way to tell gzclose()
    # not to close the original fd
    dup_fd = Libc.dup(Libc.RawFD(fd))

    gz_file = gz_dopen(backend, reinterpret(Cint, dup_fd), gzmode)
    if gz_file == C_NULL
        errno = Libc.errno()
        @static if Sys.iswindows()
            ccall(:_close, Cint, (Cint,), reinterpret(Cint, dup_fd))
        else
            ccall(:close, Cint, (Cint,), reinterpret(Cint, dup_fd))
        end
        throw(SystemError("$(name)", errno))
    end
    if gz_buf_size != Z_DEFAULT_BUFSIZE
        if gzbuffer(backend, gz_file, gz_buf_size) == -1
            @warn "gzbuffer failed, using default buffer size" requested=gz_buf_size default=Z_DEFAULT_BUFSIZE
            gz_buf_size = Z_DEFAULT_BUFSIZE
        end
    end
    iswrite = ('w' in gzmode || 'a' in gzmode)
    s = GZipStream(name, gz_file, gz_buf_size, backend, iswrite)
    iswrite || _peek(s) # Set EOF-bit for empty files (read mode only)
    return s
end
gzdopen(fd::Integer, gzmode::AbstractString, gz_buf_size::Integer; backend::GZBackend=ZLIBNG) = gzdopen(string("<fd ",fd,">"), fd, gzmode, gz_buf_size; backend)
gzdopen(fd::Integer, gz_buf_size::Integer; backend::GZBackend=ZLIBNG) = gzdopen(fd, "rb", gz_buf_size; backend)
gzdopen(fd::Integer, gzmode::AbstractString; backend::GZBackend=ZLIBNG) = gzdopen(fd, gzmode, Z_DEFAULT_BUFSIZE; backend)
gzdopen(fd::Integer; backend::GZBackend=ZLIBNG) = gzdopen(fd, "rb", Z_DEFAULT_BUFSIZE; backend)
gzdopen(fd::RawFD, args...; kwargs...) = gzdopen(Base.cconvert(Cint, fd), args...; kwargs...)
gzdopen(s::IOStream, args...; kwargs...) = gzdopen(fd(s), args...; kwargs...)


fd(s::GZipStream) = throw(MethodError(fd, (s,)))

function close(s::GZipStream)
    if s._closed
        return Z_STREAM_ERROR
    end
    s._closed = true

    ret = (@test_z_ok s gz_close(s.backend, s.gz_file))

    return ret
end

isopen(s::GZipStream) = !s._closed
isreadable(s::GZipStream) = !s._closed && !s._write
iswritable(s::GZipStream) = !s._closed && s._write

flush(s::GZipStream, fl::Integer) =
    @test_z_ok s gz_flush(s.backend, s.gz_file, Cint(fl))
flush(s::GZipStream) = flush(s, Z_SYNC_FLUSH)

truncate(s::GZipStream, n::Integer) = throw(MethodError(truncate, (GZipStream, Integer)))

# Note: seeks to byte position within uncompressed data stream
function seek(s::GZipStream, n::Integer)
    gz_seek(s.backend, s.gz_file, n, SEEK_SET) != -1 || throw(ArgumentError("seek failed: cannot seek to position $n"))
end

# Note: skips bytes within uncompressed data stream
# Mimic behavior of skip(s::IOStream, n)
function skip(s::GZipStream, n::Integer)
    gz_seek(s.backend, s.gz_file, n, SEEK_CUR) != -1 || throw(ArgumentError("skip failed: cannot skip $n bytes"))
end

position(s::GZipStream, raw::Bool=false) = raw ? gz_offset(s.backend, s.gz_file) : gz_tell(s.backend, s.gz_file)

function eof(s::GZipStream)
    s._closed && return true
    Bool(gz_eof(s.backend, s.gz_file)) && return true
    s._write && return false
    # Bytes still in zlib's output buffer => definitely not at eof (no C call).
    bytesavailable(s) > 0 && return false
    # Buffer drained: force zlib to try one more byte so its eof bit gets set.
    _peek(s) == -1
end

function peek(s::GZipStream, ::Type{UInt8})
    s._closed && throw(EOFError())
    c = gzgetc_raw(s)
    c == -1 && throw(EOFError())
    gzungetc(c, s)
    UInt8(c)
end

# Internal peek that returns -1 at EOF (used for setting EOF bit)
function _peek(s::GZipStream)
    c = gzgetc_raw(s)
    if c != -1
        gzungetc(c, s)
    end
    c
end

function unsafe_read(s::GZipStream, p::Ptr{UInt8}, n::UInt)
    remaining = n
    while remaining > 0
        ret = gzread(s, p, remaining)
        ret == 0 && throw(EOFError())
        p += ret
        remaining -= ret
    end
    nothing
end

function read(s::GZipStream, ::Type{UInt8})
    ret = gzgetc(s)  # throws EOFError or GZError on failure
    UInt8(ret)
end


function read(s::GZipStream; bufsize::Int = Z_BIG_BUFSIZE)
    buf = Array{UInt8}(undef, bufsize)
    len = 0
    while true
        ret = gzread(s, pointer(buf)+len, length(buf)-len)
        if ret == 0
            resize!(buf, len)
            return buf
        end
        len += ret
        if len == length(buf)
            resize!(buf, max(length(buf) * 2, bufsize))
        end
    end
end

readline(s::GZipStream; keep::Bool=false) = _readline(s, keep, true)

# strip_cr: readline() drops a trailing "\r\n"; readuntil(io, '\n') drops only the '\n'.
function _readline(s::GZipStream, keep::Bool, strip_cr::Bool)
    buf = s._linebuf
    # Reuse the scratch buffer, but don't let one huge line pin memory forever.
    if length(buf) < GZ_LINE_BUFSIZE || length(buf) > 65536
        resize!(buf, GZ_LINE_BUFSIZE)
    end
    pos = 1

    if gzgets(s, buf) == C_NULL      # Throws an exception on error
        return ""
    end

    while(true)
        # since gzgets didn't return C_NULL, there must be a \0 in the buffer
        eos = findnext(==(UInt8('\0')), buf, pos)::Int
        if eos == 1 || buf[eos-1] == UInt8('\n')
            endpos = eos - 1
            if !keep && endpos >= 1 && buf[endpos] == UInt8('\n')
                endpos -= 1
                if strip_cr && endpos >= 1 && buf[endpos] == UInt8('\r')
                    endpos -= 1
                end
            end
            return _str(buf, endpos)
        end

        # If we're at the end of the file, return the string
        if eof(s)
            return _str(buf, eos-1)
        end

        # Otherwise, append to the end of the previous buffer

        # Grow the buffer so that there's room for GZ_LINE_BUFSIZE chars
        chunk = max(GZ_LINE_BUFSIZE, length(buf))
        add_len = chunk - (length(buf)-eos+1)
        add_len > 0 && resize!(buf, add_len+length(buf))
        pos = eos

        # Read in the next chunk
        if gzgets(s, pointer(buf)+pos-1, chunk) == C_NULL
            # eof(s); nothing was appended
            return _str(buf, pos-1)
        end
    end
end

function Base.readuntil(s::GZipStream, delim::UInt8; keep::Bool=false)
    out = UInt8[]
    while true
        c = gzgetc_raw(s)
        c == -1 && break
        b = UInt8(c)
        if b == delim
            keep && push!(out, b)
            break
        end
        push!(out, b)
    end
    out
end

function Base.readuntil(s::GZipStream, delim::AbstractChar; keep::Bool=false)
    delim == '\n' && return _readline(s, keep, false)   # gzgets fast path
    isascii(delim) && return String(readuntil(s, UInt8(delim); keep))
    invoke(Base.readuntil, Tuple{IO,AbstractChar}, s, delim; keep)
end

write(s::GZipStream, b::UInt8) = (gzputc(s, b); 1)
unsafe_write(s::GZipStream, p::Ptr{UInt8}, nb::UInt) = Int(gzwrite(s, p, nb))

bytesavailable(s::GZipStream) = s._closed ? 0 : Int(unsafe_load(reinterpret(Ptr{Cuint}, s.gz_file)))

function readavailable(s::GZipStream)
    navail = bytesavailable(s)
    if navail == 0
        # No bytes buffered; do one read to fill the buffer
        buf = Vector{UInt8}(undef, Z_BIG_BUFSIZE)
        n = gzread(s, pointer(buf), length(buf))
        resize!(buf, n)
    else
        buf = Vector{UInt8}(undef, navail)
        gzread(s, pointer(buf), navail)
        buf
    end
end

function readbytes!(s::GZipStream, buf::AbstractVector{UInt8}, nb::Int=length(buf))
    olb = lb = length(buf)
    nr = 0
    while nr < nb
        if nr >= lb
            lb = min(nb, max(lb * 2, Z_BIG_BUFSIZE))
            resize!(buf, lb)
        end
        ret = gzread(s, pointer(buf) + nr, min(lb - nr, nb - nr))
        ret == 0 && break
        nr += ret
    end
    if lb > olb && lb > nr
        resize!(buf, nr)
    end
    nr
end

# ---------------------------------------------------------------------------
# Gzip header metadata (RFC 1952)
# ---------------------------------------------------------------------------

# Gzip header flag bits
const FTEXT    = 0x01
const FHCRC    = 0x02
const FEXTRA   = 0x04
const FNAME    = 0x08
const FCOMMENT = 0x10

# OS identifiers
const GZ_OS_NAMES = Dict{UInt8,String}(
    0x00 => "FAT (MS-DOS, OS/2, NT/Win32)",
    0x01 => "Amiga",
    0x02 => "VMS (or OpenVMS)",
    0x03 => "Unix",
    0x04 => "VM/CMS",
    0x05 => "Atari TOS",
    0x06 => "HPFS (OS/2, NT)",
    0x07 => "Macintosh",
    0x08 => "Z-System",
    0x09 => "CP/M",
    0x0a => "TOPS-20",
    0x0b => "NTFS (NT)",
    0x0c => "QDOS",
    0x0d => "Acorn RISCOS",
    0xff => "unknown",
)

"""
    GZipHeader

Gzip file header metadata (RFC 1952).

Fields:
- `mtime::UInt32` — modification time as Unix timestamp (0 = not set)
- `os::UInt8` — operating system identifier
- `xfl::UInt8` — extra flags (2 = best compression, 4 = fastest)
- `name::Union{String,Nothing}` — original filename
- `comment::Union{String,Nothing}` — file comment
- `extra::Union{Vector{UInt8},Nothing}` — extra field data
- `is_text::Bool` — hint that content is ASCII text
"""
struct GZipHeader
    mtime::UInt32
    os::UInt8
    xfl::UInt8
    name::Union{String,Nothing}
    comment::Union{String,Nothing}
    extra::Union{Vector{UInt8},Nothing}
    is_text::Bool
end

function Base.show(io::IO, h::GZipHeader)
    print(io, "GZipHeader(")
    if h.name !== nothing
        print(io, "name=", repr(h.name), ", ")
    end
    if h.mtime != 0
        print(io, "mtime=", Libc.strftime("%Y-%m-%d %H:%M:%S", h.mtime), ", ")
    end
    print(io, "os=", get(GZ_OS_NAMES, h.os, "unknown (0x$(string(h.os, base=16)))"))
    if h.comment !== nothing
        print(io, ", comment=", repr(h.comment))
    end
    if h.extra !== nothing
        print(io, ", extra=", length(h.extra), " bytes")
    end
    print(io, ")")
end

"""
    gzheader(filename::AbstractString) -> GZipHeader

Read the gzip header metadata from a `.gz` file without decompressing.
Returns a [`GZipHeader`](@ref) struct with modification time, original filename,
comment, OS identifier, and extra field data.

```julia
h = gzheader("data.gz")
h.name     # original filename, or nothing
h.mtime    # modification time as Unix timestamp
h.comment  # file comment, or nothing
```
"""
function gzheader(filename::AbstractString)
    Base.open(filename, "r") do io
        _read_gzheader(io)
    end
end

function _read_gzheader(io::IO)
    # Magic number
    id1 = read(io, UInt8)
    id2 = read(io, UInt8)
    (id1 == 0x1f && id2 == 0x8b) || throw(ArgumentError("not a gzip file"))

    # Compression method
    cm = read(io, UInt8)
    cm == 0x08 || throw(ArgumentError("unsupported compression method: $cm"))

    # Flags
    flg = read(io, UInt8)

    # Modification time (little-endian uint32)
    mtime = ltoh(read(io, UInt32))

    # Extra flags and OS
    xfl = read(io, UInt8)
    os = read(io, UInt8)

    # FEXTRA
    extra = nothing
    if (flg & FEXTRA) != 0
        xlen = ltoh(read(io, UInt16))
        extra = read(io, xlen)
    end

    # FNAME (null-terminated)
    name = nothing
    if (flg & FNAME) != 0
        name = _read_cstring(io)
    end

    # FCOMMENT (null-terminated)
    comment = nothing
    if (flg & FCOMMENT) != 0
        comment = _read_cstring(io)
    end

    # FHCRC (skip 2-byte CRC16)
    if (flg & FHCRC) != 0
        read(io, UInt16)
    end

    GZipHeader(mtime, os, xfl, name, comment, extra, (flg & FTEXT) != 0)
end

function _read_cstring(io::IO)
    buf = UInt8[]
    while true
        b = read(io, UInt8)
        b == 0x00 && break
        push!(buf, b)
    end
    String(buf)
end
