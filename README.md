# GZip.jl: A Julia interface for gzip functions in zlib

[![GZip](http://pkg.julialang.org/badges/GZip_0.3.svg)](http://pkg.julialang.org/?pkg=GZip)
[![GZip](http://pkg.julialang.org/badges/GZip_0.4.svg)](http://pkg.julialang.org/?pkg=GZip)
[![GZip](http://pkg.julialang.org/badges/GZip_0.5.svg)](http://pkg.julialang.org/?pkg=GZip)
[![Build Status](https://travis-ci.org/JuliaIO/GZip.jl.svg?branch=master)](https://travis-ci.org/JuliaIO/GZip.jl)
[![Coverage Status](https://coveralls.io/repos/JuliaIO/GZip.jl/badge.svg)](https://coveralls.io/r/JuliaIO/GZip.jl)

This module provides a wrapper for the gzip related functions of
[zlib](http://zlib.net), a free, general-purpose, legally
unencumbered, lossless data-compression library. These functions
allow the reading and writing of gzip files.

Install with `Pkg.add("GZip")` at the Julia prompt.

Usage
-----

Typical usage would be something like

```julia
import GZip

fh = GZip.open("infile.gz")
s = readline(fh)
...
close(fh)


...
s = "gzip is part of zlib, a free, general-purpose, " *
    "legally unencumbered, lossless data-compression library"

fh = GZip.open("outfile.gz", "w")
write(fh, s)
...
close(fh)
```


See the [documentation](https://gzipjl.readthedocs.org/en/latest/)
for additional information.
