using Compat
import Compat: readstring
using GZip
using Base.Test

##########################
# test_context("GZip tests")
##########################

#for epoch in 1:10

tmp = mktempdir()

test_infile = @__FILE__
test_compressed = joinpath(tmp, "runtests.jl.gz")
test_empty = joinpath(tmp, "empty.jl.gz")

if is_windows()
    gunzip = "gunzip.exe"
elseif is_unix()
    gunzip = "gunzip"
else
    throw(ErrorException("Unknown operating system"))
end

test_gunzip = true
try
    run(pipeline(`which $gunzip`, DevNull))
catch
    test_gunzip = false
end

try
    #########################
    # test_group("Compress Test1: gzip.jl")
    ##########################

    data = open(readstring, test_infile);

    first_char = data[1]

    gzfile = gzopen(test_compressed, "wb")
    @test write(gzfile, data) == length(data.data)
    @test close(gzfile) == Z_OK
    @test close(gzfile) != Z_OK

    @test_throws EOFError write(gzfile, data)

    if test_gunzip
        data2 = readstring(`$gunzip -c $test_compressed`)
        @test data == data2
    end

    data3 = gzopen(readstring, test_compressed)
    @test data == data3

    # Test gzfdio
    raw_file = open(test_compressed, "r")
    gzfile = gzdopen(fd(raw_file), "r")
    data4 = readstring(gzfile)
    close(gzfile)
    close(raw_file)
    @test data == data4

    # Test peek
    gzfile = gzopen(test_compressed, "r")
    @test peek(gzfile) == @compat UInt(first_char)
    readstring(gzfile)
    @test peek(gzfile) == -1
    close(gzfile)

    # Screw up the file
    raw_file = open(test_compressed, "r+")
    seek(raw_file, 3) # leave the gzip magic 2-byte header
    write(raw_file, zeros(UInt8, 10))
    close(raw_file)

    @compat try
        gzopen(readstring, test_compressed)
        throw(ErrorException("Expecting ArgumentError or similar"))
    catch ex
        @test typeof(ex) <: Union{ArgumentError,ZError,GZError} ||
              contains(ex.msg, "too many arguments")
    end

    ##########################
    # test_group("gzip file function tests (writing)")
    ##########################
    gzfile = gzopen(test_compressed, "wb")
    write(gzfile, data) == length(data.data)
    @test flush(gzfile) == Z_OK

    NEW = GZip.GZLIB_VERSION > "1.2.3.9"
    pos = position(gzfile)
    NEW && (pos2 = position(gzfile,true))
    @test_throws ErrorException seek(gzfile, 100)   # can't seek backwards on write
    @test position(gzfile) == pos
    NEW && (@test position(gzfile,true) == pos2)
    @test skip(gzfile, 100)
    @test position(gzfile) == pos + 100
    NEW && (@test position(gzfile,true) == pos2)

    @test_throws MethodError truncate(gzfile, 100)
    @test_throws MethodError seekend(gzfile)

    @test close(gzfile) == Z_OK

    gzopen(test_empty, "w") do io
        a = "".data
        @test gzwrite(io, pointer(a), length(a)*sizeof(eltype(a))) == @compat Int32(0)
    end

    ##########################
    # test_group("gzip file function tests (strategy read/write)")
    ##########################

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
            gzfile = gzopen(test_compressed, "wb$level$ch")
            @test write(gzfile, data) == length(data.data)
            @test close(gzfile) == Z_OK

            file_size = filesize(test_compressed)

            #println("wb$level$ch: ", file_size)

            if ch == 'T'
                @test(file_size == length(data.data))
            elseif level == 0
                @test(file_size > length(data.data))
            else
                @test(file_size < length(data.data))
            end

            # readline test
            gzf = gzopen(test_compressed)
            s = IOBuffer()
            while !eof(gzf)
                write(s, readline(gzf))
            end
            data2 = takebuf_string(s);

            # readuntil test
            seek(gzf, 0)
            while !eof(gzf)
                write(s, readuntil(gzf, 'a'))
            end
            data3 = takebuf_string(s);
            close(gzf)

            @test(data == data2)
            @test(data == data3)

        end
    end

    # Test to create and read an empty file
    gzfile = gzopen(test_compressed, "wb")
    @test write(gzfile, "") == 0
    @test close(gzfile) == Z_OK
    gzfile = gzopen(test_compressed, "r")
    @test eof(gzfile) == true
    @test close(gzfile) == Z_OK

    ##########################
    # test_group("gzip array/matrix tests (write/read)")
    ##########################

    let BUFSIZE = 65536
        for level = 0:3:6
            for T in [Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Int128,UInt128,
                      Float32,Float64,Complex64,Complex128]

                minval = 34567
                try
                    minval = min(typemax(T), 34567)
                catch
                    # do nothing
                end

                # Ordered array
                b = zeros(T, BUFSIZE)
                if !isa(T, Complex)
                    for i = 1:length(b)
                        b[i] = (i-1)%minval;
                    end
                else
                    for i = 1:length(b)
                        b[i] = (i-1)%minval - (minval-(i-1))%minval * im
                    end
                end

                # Random array
                if isa(T, AbstractFloat)
                    r = (T)[rand(BUFSIZE)...];
                elseif isa(T, Complex64)
                    r = Int32[rand(BUFSIZE)...] + Int32[rand(BUFSIZE)...] * im
                elseif isa(T, Complex128)
                    r = Int64[rand(BUFSIZE)...] + Int64[rand(BUFSIZE)...] * im
                else
                    r = b[rand(1:BUFSIZE, BUFSIZE)];
                end

                # Array file
                b_array_fn = joinpath(tmp, "b_array.raw.gz")
                r_array_fn = joinpath(tmp, "r_array.raw.gz")

                gzaf_b = gzopen(b_array_fn, "w$level")
                write(gzaf_b, b)
                close(gzaf_b)

                #println("$T ($level) ordered: $(filesize(b_array_fn))")

                gzaf_r = gzopen(r_array_fn, "w$level")
                write(gzaf_r, r)
                close(gzaf_r)

                #println("$T ($level) random: $(filesize(r_array_fn))")

                b2 = zeros(T, BUFSIZE)
                r2 = zeros(T, BUFSIZE)

                b2_infile = gzopen(b_array_fn)
                read(b2_infile, b2);
                close(b2_infile)

                r2_infile = gzopen(r_array_fn)
                read(r2_infile, r2);
                close(r2_infile)

                @test b == b2
                @test r == r2
            end
        end
    end
finally
    rm(tmp, recursive=true)
end

#end  # for epoch
