GZip.jl: A Julia interface for gzip functions in zlib
========================================================

This module provides a wrapper for the gzip related functions of
[zlib](http://zlib.net/>), a free, general-purpose, legally
unencumbered, lossless data-compression library. These functions
allow the reading and writing of gzip files.

Install with `Pkg.add("GZip")` at the Julia prompt.

Usage
-----

Typical usage would be something like

```julia
import GZip

fh = GZip.open("infile.gz")
readline(fh, s)
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


See the [documentation at ReadTheDocs](https://gzipjl.readthedocs.org/en/latest/) 
for additional information.
