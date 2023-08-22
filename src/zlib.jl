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

using .ZlibNG_h

#const GZLIB_VERSION = unsafe_string(ZlibNG_h.zlibng_version)
#const ZLIB_VERSION  = tuple([parse(Int, c) for c in split(GZLIB_VERSION, '.')]...)

# Constants for use with gzbuffer
const Z_DEFAULT_BUFSIZE = 8192
const Z_BIG_BUFSIZE = 131072

# Create ZFileOffset alias
# Use 64bit if the *64 functions are available or zlib is compiles with 64bit
# file offset.

# Get compile-time option flags
const zlib_compile_flags = ZlibNG_h.zng_zlibCompileFlags()
const z_off_t_sz = 2 << ((zlib_compile_flags >> 6) & UInt(3))
if z_off_t_sz == 8 || (!Sys.iswindows() && isdefined(GZip.Zlib_h, :gzopen64))
    const ZFileOffset = Int64
elseif z_off_t_sz == 4
    const ZFileOffset = Int32
else
    error("Can't figure out what to do with ZFileOffset. sizeof(z_off_t) = ", z_off_t_sz)
end

# Zlib errors as Exceptions
zerror(e::Integer) = unsafe_string(zError(e))
mutable struct ZError <: Exception
    err::Cint
    err_str::AbstractString

    ZError(e::Integer) = (e == Z_ERRNO ? new(e, strerror()) : new(e, zerror(e)))
end
