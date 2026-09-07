using GZip
using GZip: gzgetc, gzungetc, gzgets, gzputc, gzwrite, gzread, gzbuffer,
            Z_OK
using Test

test_infile = @__FILE__

@static if Sys.iswindows()
    gunzip = "gunzip.exe"
elseif Sys.isunix()
    gunzip = "gunzip"
end

test_gunzip = true
try
    run(pipeline(`which $gunzip`, devnull))
catch
    global test_gunzip
    test_gunzip = false
end

function run_backend_tests(; backend=GZip.ZLIB)
    tmp = mktempdir()
    test_compressed = joinpath(tmp, "runtests.jl.gz")
    test_empty = joinpath(tmp, "empty.jl.gz")

    try

    @testset "Compress and decompress" begin
        data = open(x->read(x, String), test_infile);

        first_char = data[1]

        gzfile = gzopen(test_compressed, "wb"; backend)
        @test write(gzfile, data) == sizeof(data)
        @test close(gzfile) == Z_OK
        @test close(gzfile) != Z_OK

        @test_throws EOFError write(gzfile, data)

        if test_gunzip
            data2 = read(`$gunzip -c $test_compressed`, String)
            @test data == data2
        end

        data3 = gzopen(x->read(x, String), test_compressed; backend)
        @test data == data3

        # Test gzfdio
        @test_throws "No such file or directory" gzopen("wrong_file.gz", "r"; backend)
        @test_throws "Bad file descriptor" gzdopen("wrong_fd.gz", -1, "r", 1024; backend)

        raw_file = open(test_compressed, "r")
        gzfile = gzdopen(fd(raw_file), "r"; backend)
        data4 = read(gzfile, String)
        close(gzfile)
        close(raw_file)
        @test data == data4

        # Test peek
        gzfile = gzopen(test_compressed, "r"; backend)
        @test peek(gzfile) == UInt8(first_char)
        read(gzfile, String)
        @test_throws EOFError peek(gzfile)
        close(gzfile)

        # Corrupt header (leave the gzip magic 2-byte header intact)
        raw_file = open(test_compressed, "r+")
        seek(raw_file, 3)
        write(raw_file, zeros(UInt8, 10))
        close(raw_file)

        @test_throws Union{ArgumentError,ZError,GZError} gzopen(x->read(x, String), test_compressed; backend)
    end

    @testset "readbytes!" begin
        gzopen(test_compressed, "w"; backend) do io
            write(io, "hello world")
        end
        gzopen(test_compressed; backend) do io
            buf = Vector{UInt8}(undef, 5)
            @test readbytes!(io, buf) == 5
            @test buf == b"hello"
            buf2 = Vector{UInt8}(undef, 100)
            @test readbytes!(io, buf2) == 6
            @test buf2[1:6] == b" world"
        end
    end

    @testset "readline keep keyword" begin
        gzopen(test_compressed, "w"; backend) do io
            write(io, "line1\nline2\nline3")
        end

        # Default (keep=false) should strip newlines
        gzopen(test_compressed; backend) do io
            @test readline(io) == "line1"
            @test readline(io) == "line2"
            @test readline(io) == "line3"
        end

        # keep=true should preserve newlines
        gzopen(test_compressed; backend) do io
            @test readline(io; keep=true) == "line1\n"
            @test readline(io; keep=true) == "line2\n"
            @test readline(io; keep=true) == "line3"
        end
    end

    @testset "Writing" begin
        data = open(x->read(x, String), test_infile);

        gzfile = gzopen(test_compressed, "wb"; backend)
        @test write(gzfile, data) == sizeof(data)
        @test flush(gzfile) == Z_OK

        NEW = GZip.ZLIB_VERSION >= (1, 2, 4)
        pos = position(gzfile)
        NEW && (pos2 = position(gzfile,true))
        @test_throws ArgumentError seek(gzfile, 0)   # can't seek backwards on write
        @test position(gzfile) == pos
        NEW && (@test position(gzfile,true) == pos2)
        @test skip(gzfile, 100)
        @test position(gzfile) == pos + 100
        NEW && (@test position(gzfile,true) == pos2)

        @test_throws MethodError truncate(gzfile, 100)
        @test_throws MethodError seekend(gzfile)

        @test close(gzfile) == Z_OK

        gzopen(test_empty, "w"; backend) do io
            a = UInt8[]
            @test gzwrite(io, pointer(a), length(a)*sizeof(eltype(a))) == Int32(0)
        end

        # write(::GZipStream, ::UInt8) should return 1 (byte count, not value)
        gzopen(test_compressed, "w"; backend) do io
            @test write(io, 0x0a) == 1
            @test write(io, 0xff) == 1
        end

        # Test writing SubArrays (views)
        gzfile = gzopen(test_compressed, "wb"; backend)
        arr = collect(0x00:0xff)
        @test write(gzfile, @view arr[1:128]) == 128
        @test write(gzfile, @view arr[129:256]) == 128
        close(gzfile)
        gzfile = gzopen(test_compressed, "r"; backend)
        @test read(gzfile) == arr
        close(gzfile)
    end

    @testset "Strategy read/write" begin
        data = open(x->read(x, String), test_infile);

        # rewrite the test file
        modes = "fhR "
        if GZip.ZLIB_VERSION >= (1,2,5,2)
            modes = "fhRFT "
        end
        for ch in modes
            if ch == ' '
                ch = ""
            end
            for level = 0:9
                gzfile = gzopen(test_compressed, "wb$level$ch"; backend)
                @test write(gzfile, data) == sizeof(data)
                @test close(gzfile) == Z_OK

                file_size = filesize(test_compressed)

                if ch == 'T'
                    @test(file_size == sizeof(data))
                elseif level == 0
                    @test(file_size > sizeof(data))
                else
                    @test(file_size < sizeof(data))
                end

                # readline test
                gzf = gzopen(test_compressed; backend)
                s = IOBuffer()
                while !eof(gzf)
                    write(s, readline(gzf; keep=true))
                end
                data2 = String(take!(s));

                # readuntil test
                seek(gzf, 0)
                while !eof(gzf)
                    write(s, readuntil(gzf, 'a'; keep=true))
                end
                data3 = String(take!(s));
                close(gzf)

                @test(data == data2)
                @test(data == data3)

            end
        end

        # Empty file
        gzfile = gzopen(test_compressed, "wb"; backend)
        @test write(gzfile, "") == 0
        @test close(gzfile) == Z_OK
        gzfile = gzopen(test_compressed, "r"; backend)
        @test eof(gzfile) == true
        @test close(gzfile) == Z_OK
    end

    @testset "Array/matrix read/write" begin
        BUFSIZE = 65536
        for level = 0:3:6
            for T in [Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Int128,UInt128,
                      Float32,Float64,ComplexF32,ComplexF64]

                minval = 34567
                try
                    minval = min(typemax(T), 34567)
                catch
                    # do nothing
                end

                # Ordered array
                b = zeros(T, BUFSIZE)
                if !(T <: Complex)
                    for i = 1:length(b)
                        b[i] = (i-1)%minval;
                    end
                else
                    for i = 1:length(b)
                        b[i] = (i-1)%minval - (minval-(i-1))%minval * im
                    end
                end

                # Random array
                if T <: AbstractFloat
                    r = T.(rand(BUFSIZE))
                elseif T <: Complex
                    RT = real(T)
                    r = Complex{RT}.(rand(RT, BUFSIZE), rand(RT, BUFSIZE))
                else
                    r = b[rand(1:BUFSIZE, BUFSIZE)]
                end

                # Array file
                b_array_fn = joinpath(tmp, "b_array.raw.gz")
                r_array_fn = joinpath(tmp, "r_array.raw.gz")

                gzaf_b = gzopen(b_array_fn, "w$level"; backend)
                write(gzaf_b, b)
                close(gzaf_b)

                gzaf_r = gzopen(r_array_fn, "w$level"; backend)
                write(gzaf_r, r)
                close(gzaf_r)

                b2 = zeros(T, BUFSIZE)
                r2 = zeros(T, BUFSIZE)

                b2_infile = gzopen(b_array_fn; backend)
                read!(b2_infile, b2);
                close(b2_infile)

                r2_infile = gzopen(r_array_fn; backend)
                read!(r2_infile, r2);
                close(r2_infile)

                @test b == b2
                @test r == r2
            end
        end
    end

    # --- Tests inspired by zlib example.c and CPython test_gzip.py ---

    @testset "Low-level gzputc/gzgetc/gzungetc/gzgets sequence" begin
        # Mirrors zlib's test/example.c test_gzio
        fn = joinpath(tmp, "lowlevel.gz")
        gzfile = gzopen(fn, "wb"; backend)
        gzputc(gzfile, UInt8('h'))
        @test gzwrite(gzfile, pointer("ello"), 4) == 4
        @test write(gzfile, ", world!")  == 8
        @test close(gzfile) == Z_OK

        # Read back and verify
        gzfile = gzopen(fn, "rb"; backend)
        @test read(gzfile, UInt8) == UInt8('h')

        # Read remaining
        buf = read(gzfile, String)
        @test buf == "ello, world!"
        close(gzfile)

        # Seek backward during read (SEEK_CUR via seek to absolute position)
        gzfile = gzopen(fn, "rb"; backend)
        full = read(gzfile, String)
        @test full == "hello, world!"
        seek(gzfile, 8)
        @test position(gzfile) == 8
        rest = read(gzfile, String)
        @test rest == "orld!"

        # gzungetc: push back a byte and read it again
        seek(gzfile, 5)
        c = read(gzfile, UInt8)
        @test c == UInt8(',')
        gzungetc(c, gzfile)
        c2 = read(gzfile, UInt8)
        @test c2 == UInt8(',')
        close(gzfile)
    end

    @testset "Forward seek on write produces null bytes" begin
        fn = joinpath(tmp, "seekwrite.gz")
        gzfile = gzopen(fn, "wb"; backend)
        write(gzfile, "AB")
        skip(gzfile, 3)  # skip 3 bytes (padded with nulls)
        write(gzfile, "CD")
        close(gzfile)

        gzfile = gzopen(fn, "rb"; backend)
        data = read(gzfile)
        close(gzfile)
        @test data == UInt8['A', 'B', 0, 0, 0, 'C', 'D']
    end

    @testset "Position mid-stream" begin
        fn = joinpath(tmp, "position.gz")
        gzfile = gzopen(fn, "wb"; backend)
        @test position(gzfile) == 0
        write(gzfile, "hello")
        @test position(gzfile) == 5
        write(gzfile, " world")
        @test position(gzfile) == 11
        close(gzfile)

        gzfile = gzopen(fn, "rb"; backend)
        @test position(gzfile) == 0
        read(gzfile, 5)
        @test position(gzfile) == 5
        read(gzfile, String)
        @test position(gzfile) == 11
        close(gzfile)
    end

    @testset "IO on closed stream" begin
        fn = joinpath(tmp, "closed.gz")
        gzopen(fn, "w"; backend) do io
            write(io, "data")
        end

        gzfile = gzopen(fn, "r"; backend)
        close(gzfile)

        # All operations on closed stream should throw
        @test_throws EOFError read(gzfile, UInt8)
        @test_throws EOFError read(gzfile, String)
        @test_throws EOFError gzgetc(gzfile)
    end

    @testset "Zero-length write" begin
        fn = joinpath(tmp, "zerolen.gz")
        gzopen(fn, "w"; backend) do io
            @test write(io, UInt8[]) == 0
            write(io, "hello")
            @test write(io, UInt8[]) == 0
        end
        @test gzopen(x->read(x, String), fn; backend) == "hello"
    end

    @testset "Concatenated/multi-member gzip (append)" begin
        fn = joinpath(tmp, "multi.gz")
        gzopen(fn, "wb"; backend) do io
            write(io, "first")
        end
        gzopen(fn, "ab"; backend) do io
            write(io, "second")
        end
        data = gzopen(x->read(x, String), fn; backend)
        @test data == "firstsecond"
    end

    @testset "Corrupt CRC trailer" begin
        fn = joinpath(tmp, "badcrc.gz")
        gzopen(fn, "wb"; backend) do io
            write(io, "hello world " ^ 100)
        end

        # Corrupt the last 8 bytes (CRC32 + ISIZE trailer)
        raw = read(fn)
        raw[end-7:end] .= 0xff
        write(fn, raw)

        # CRC error is detected on close; gzopen do-block calls close which
        # should propagate the error
        @test_throws Union{GZError, ZError} gzopen(fn; backend) do io
            read(io, String)
        end
    end

    @testset "Truncated file" begin
        fn = joinpath(tmp, "trunc.gz")
        gzopen(fn, "wb"; backend) do io
            write(io, "hello world " ^ 100)
        end

        raw = read(fn)

        # Truncated mid-compressed-body (keep first 20 bytes)
        fn_trunc = joinpath(tmp, "trunc_body.gz")
        write(fn_trunc, raw[1:min(20, length(raw))])
        @test_throws Union{GZError, ZError, EOFError, ArgumentError} gzopen(fn_trunc; backend) do io
            read(io, String)
        end

        # Truncated — missing trailer (remove last 8 bytes)
        if length(raw) > 8
            fn_notrailer = joinpath(tmp, "trunc_trailer.gz")
            write(fn_notrailer, raw[1:end-8])
            @test_throws Union{GZError, ZError, EOFError} gzopen(fn_notrailer; backend) do io
                read(io, String)
            end
        end
    end

    finally
        rm(tmp, recursive=true)
    end
end

@testset "zlib backend" begin
    run_backend_tests(; backend=GZip.ZLIB)
end

@testset "zlib-ng backend" begin
    run_backend_tests(; backend=GZip.ZLIBNG)
end

@testset "Cross-backend compatibility" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "cross.gz")
    try
        data = "cross-backend test data: αβγ 🎉"

        # Write with zlib-ng, read with zlib
        gzopen(fn, "w"; backend=GZip.ZLIBNG) do io
            write(io, data)
        end
        @test gzopen(x->read(x, String), fn; backend=GZip.ZLIB) == data

        # Write with zlib, read with zlib-ng
        gzopen(fn, "w"; backend=GZip.ZLIB) do io
            write(io, data)
        end
        @test gzopen(x->read(x, String), fn; backend=GZip.ZLIBNG) == data
    finally
        rm(tmp, recursive=true)
    end
end

@testset "isreadable/iswritable" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "rw.gz")
    try
        # Write mode
        gzopen(fn, "w") do io
            @test iswritable(io)
            @test !isreadable(io)
            write(io, "test")
        end

        # Read mode
        gzopen(fn) do io
            @test isreadable(io)
            @test !iswritable(io)
        end

        # Closed stream
        s = gzopen(fn)
        close(s)
        @test !isreadable(s)
        @test !iswritable(s)
    finally
        rm(tmp, recursive=true)
    end
end

@testset "read(::GZipStream) bulk read" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "bulk.gz")
    try
        data = rand(UInt8, 500_000)
        gzopen(fn, "w") do io
            write(io, data)
        end

        # read(gz) should return the same bytes
        result = gzopen(fn) do io
            read(io)
        end
        @test result == data
        @test result isa Vector{UInt8}

        # Empty file
        gzopen(fn, "w") do io; end
        result = gzopen(fn) do io
            read(io)
        end
        @test result == UInt8[]
    finally
        rm(tmp, recursive=true)
    end
end

# The 61-byte gzip file GNU gzip produces for a file named "testfile.txt"
# containing "Hello from a real gzip file\n". Kept as a literal rather than a
# checked-in .gz so the repo carries no binary fixtures, while still testing
# our parser against bytes emitted by an independent implementation.
const GNU_GZIP_FIXTURE = UInt8[
    0x1f, 0x8b, 0x08, 0x08, 0x2f, 0xc4, 0xd6, 0x69, 0x00, 0x03, 0x74, 0x65,
    0x73, 0x74, 0x66, 0x69, 0x6c, 0x65, 0x2e, 0x74, 0x78, 0x74, 0x00, 0xf3,
    0x48, 0xcd, 0xc9, 0xc9, 0x57, 0x48, 0x2b, 0xca, 0xcf, 0x55, 0x48, 0x54,
    0x28, 0x4a, 0x4d, 0xcc, 0x51, 0x48, 0xaf, 0xca, 0x2c, 0x50, 0x48, 0xcb,
    0xcc, 0x49, 0xe5, 0x02, 0x00, 0x11, 0x12, 0xe8, 0x28, 0x1c, 0x00, 0x00,
    0x00,
]

zcrc32(data) = ccall((:crc32, GZip.Zlib_h.Zlib_jll.libz_path), Culong,
                     (Culong, Ptr{UInt8}, Cuint), 0, data, length(data)) % UInt32

"""
Write a gzip file at `path` holding `content`, with arbitrary RFC 1952 header
fields. zlib always emits a bare 10-byte header (FLG=0) and gives us no way to
set FNAME/FCOMMENT/FEXTRA/MTIME, so we let GZip.jl produce the deflate stream
and trailer, then splice on a header we build ourselves.
"""
function write_gz_with_header(path, content; mtime::Integer=0, os::UInt8=0x03,
                              xfl::UInt8=0x00, name=nothing, comment=nothing,
                              extra=nothing, fhcrc::Bool=false, ftext::Bool=false)
    payload = path * ".tmp"
    gzopen(payload, "w") do io
        write(io, content)
    end
    raw = read(payload)
    rm(payload)
    @assert raw[4] == 0x00 "expected zlib to emit a flagless 10-byte header"
    body = raw[11:end]   # deflate stream + CRC32/ISIZE trailer

    flg = 0x00
    ftext                && (flg |= 0x01)
    fhcrc                && (flg |= 0x02)
    extra   !== nothing  && (flg |= 0x04)
    name    !== nothing  && (flg |= 0x08)
    comment !== nothing  && (flg |= 0x10)

    head = IOBuffer()
    write(head, UInt8[0x1f, 0x8b, 0x08, flg])
    write(head, htol(UInt32(mtime)))
    write(head, xfl, os)
    if extra !== nothing
        write(head, htol(UInt16(length(extra))))
        write(head, extra)
    end
    name    !== nothing && (write(head, name);    write(head, 0x00))
    comment !== nothing && (write(head, comment); write(head, 0x00))
    bytes = take!(head)
    # FHCRC is the low 16 bits of the CRC-32 over the header up to this point,
    # and zlib *does* verify it, so it has to be right or the file won't inflate.
    fhcrc && (bytes = [bytes; reinterpret(UInt8, [htol(UInt16(zcrc32(bytes) & 0xffff))])])

    write(path, [bytes; body])
    path
end

@testset "gzheader" begin
    tmp = mktempdir()
    try
        # Bytes from GNU gzip: FNAME and MTIME set, OS = Unix
        fixture = joinpath(tmp, "testfile.txt.gz")
        write(fixture, GNU_GZIP_FIXTURE)
        h = gzheader(fixture)
        @test h isa GZipHeader
        @test h.name == "testfile.txt"
        @test h.mtime > 0
        @test h.os == 0x03  # Unix
        @test h.comment === nothing
        @test h.extra === nothing

        # Content should be readable
        content = gzopen(fixture) do io
            read(io, String)
        end
        @test content == "Hello from a real gzip file\n"

        # GZip.jl-created file (zlib doesn't set FNAME/MTIME by default)
        fn = joinpath(tmp, "header.gz")
        gzopen(fn, "w") do io
            write(io, "hello")
        end
        h2 = gzheader(fn)
        @test h2 isa GZipHeader
        @test h2.name === nothing
        @test h2.mtime == 0

        # Every optional header field, individually and together. The old
        # checked-in fixture only ever exercised FNAME.
        cases = [
            (; name="a.txt"),
            (; comment="a comment"),
            (; extra=UInt8[0x01, 0x02, 0x03, 0x04]),
            (; fhcrc=true),
            (; ftext=true),
            (; name="b.txt", comment="c", extra=UInt8[0xaa, 0xbb], fhcrc=true, ftext=true),
            (; mtime=1_700_000_000, os=0x00, xfl=0x02),
        ]
        for (i, kw) in enumerate(cases)
            fn3 = joinpath(tmp, "hdr$i.gz")
            write_gz_with_header(fn3, "payload $i"; kw...)
            h3 = gzheader(fn3)
            @test h3.name == get(kw, :name, nothing)
            @test h3.comment == get(kw, :comment, nothing)
            @test h3.extra == get(kw, :extra, nothing)
            @test h3.is_text == get(kw, :ftext, false)
            @test h3.mtime == UInt32(get(kw, :mtime, 0))
            @test h3.os == get(kw, :os, 0x03)
            @test h3.xfl == get(kw, :xfl, 0x00)
            # ...and the file must still be a valid gzip stream
            @test gzopen(fn3) do io
                read(io, String)
            end == "payload $i"
        end

        # Not a gzip file
        nongz = joinpath(tmp, "notgz.txt")
        write(nongz, "plain text")
        @test_throws ArgumentError gzheader(nongz)

        # Truncated header
        trunc = joinpath(tmp, "trunc.gz")
        write(trunc, GNU_GZIP_FIXTURE[1:6])
        @test_throws Exception gzheader(trunc)
    finally
        rm(tmp, recursive=true)
    end
end

@testset "gzfread/gzfwrite (>4GB safe)" begin
    # Verify that gzread/gzwrite work through gzfread/gzfwrite
    # by testing round-trip with various sizes
    tmp = mktempdir()
    fn = joinpath(tmp, "freadwrite.gz")
    try
        for sz in [0, 1, 8192, 131072, 1_000_000]
            data = rand(UInt8, sz)
            gzopen(fn, "w") do io
                write(io, data)
            end
            result = gzopen(fn) do io
                read(io)
            end
            @test result == data
        end
    finally
        rm(tmp, recursive=true)
    end
end

@testset "read(s, UInt8) EOF handling" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "byte.gz")
    try
        gzopen(fn, "w") do io
            write(io, "ABC")
        end

        gzopen(fn) do io
            @test read(io, UInt8) == UInt8('A')
            @test read(io, UInt8) == UInt8('B')
            @test read(io, UInt8) == UInt8('C')
            @test_throws EOFError read(io, UInt8)
        end
    finally
        rm(tmp, recursive=true)
    end
end

@testset "gzdopen fd cleanup on failure" begin
    # gzdopen with invalid fd should not leak the duplicated fd
    # The test at line 49 verifies the error is thrown;
    # here we verify we can open many bad fds without running out
    for _ in 1:100
        try
            gzdopen("bad", -1, "r", 1024)
        catch e
            @test e isa SystemError
        end
    end
end

@testset "isopen" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "isopen.gz")
    try
        gzopen(fn, "w") do io
            @test isopen(io)
            write(io, "test")
        end
        s = gzopen(fn)
        @test isopen(s)
        close(s)
        @test !isopen(s)
    finally
        rm(tmp, recursive=true)
    end
end

@testset "peek throws EOFError at EOF" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "peek.gz")
    try
        gzopen(fn, "w") do io
            write(io, 0x0a)
        end
        gzopen(fn, "r") do io
            @test peek(io) == 0x0a
            read(io)
            @test_throws EOFError peek(io)
        end
        # Closed stream
        s = gzopen(fn, "r")
        close(s)
        @test_throws EOFError peek(s)
    finally
        rm(tmp, recursive=true)
    end
end

@testset "bytesavailable" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "ba.gz")
    try
        gzopen(fn, "w") do io
            write(io, "hello world")
        end
        gzopen(fn) do io
            # After open, peek has been called so buffer is filled
            @test bytesavailable(io) == 11
            read(io, UInt8)
            @test bytesavailable(io) == 10
            read(io)
            @test bytesavailable(io) == 0
        end
        # Closed stream
        s = gzopen(fn)
        close(s)
        @test bytesavailable(s) == 0
    finally
        rm(tmp, recursive=true)
    end
end

@testset "readavailable" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "ra.gz")
    try
        data = rand(UInt8, 10_000)
        gzopen(fn, "w") do io
            write(io, data)
        end
        gzopen(fn) do io
            chunks = UInt8[]
            while !eof(io)
                append!(chunks, readavailable(io))
            end
            @test chunks == data
        end
    finally
        rm(tmp, recursive=true)
    end
end

@testset "unsafe_read" begin
    tmp = mktempdir()
    fn = joinpath(tmp, "unsafe.gz")
    try
        data = rand(UInt8, 100_000)
        gzopen(fn, "w") do io
            write(io, data)
        end
        gzopen(fn) do io
            buf = Vector{UInt8}(undef, length(data))
            read!(io, buf)
            @test buf == data
            @test_throws EOFError read!(io, Vector{UInt8}(undef, 1))
        end
    finally
        rm(tmp, recursive=true)
    end
end

@testset "Non-ASCII filenames" begin
    tmp = mktempdir()
    try
        for name in ["données.gz", "日本語.gz", "αβγ.gz", "emoji🎉.gz"]
            fn = joinpath(tmp, name)
            data = "test data for $name"
            gzopen(fn, "w") do io
                write(io, data)
            end
            result = gzopen(fn) do io
                read(io, String)
            end
            @test result == data
        end
    finally
        rm(tmp, recursive=true)
    end
end


using Aqua
Aqua.test_all(GZip)
