# GZip.jl: A Julia interface for gzip functions in zlib

[![Documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaio.github.io/GZip.jl/dev)

This module provides a wrapper for the gzip related functions of
[zlib](http://zlib.net), a free, general-purpose, legally
unencumbered, lossless data-compression library. These functions
allow the reading and writing of gzip files.

Usage
-----

Typical usage would be something like

```julia
using GZip

# Write some text into a compressed .gz file
s = "gzip is part of zlib, a free, general-purpose, " *
    "legally unencumbered, lossless data-compression library"
fh = GZip.open("testfile.gz", "w")
write(fh, s)
close(fh)

# Read back the data
fh = GZip.open("testfile.gz")
s = readline(fh)
close(fh)
```

## Notes

-   This interface is only for gzipped files, not the streaming zlib compression interface. Internally, it depends on/uses the streaming interface, but the gzip related functions are higher level functions pertaining to gzip files only.                                            
-   `GZipStream` is an implementation of `IO` and can be used virtually anywhere `IO` is used.
-   This implementation mimics the `IOStream` implementation, and should be a drop-in replacement for `IOStream`, with some caveats:
    -   `seekend` and `truncate` are not available
    -   `readuntil` is available, but is not very efficient. (But `readline` works fine.)                        
                                                                                                                 
In addition to `open`, `gzopen`, and `gzdopen`, the following `IO`/`IOStream` functions are supported:                 
-   `close()`                                                                                                    
-   `flush()`                                                                                                    
-   `seek()`                                                                                                     
-   `skip()`                                                                                                     
-   `position()`                                                                                                 
-   `eof()`                                                                                                      
-   `read()`                                                                                                     
-   `readuntil()`                                                                                                
-   `readline()`                                                                                                 
-   `write()`                                                                                                    
-   `peek()`                                                                                                     
                                                                                                                 
Due to limitations in `zlib`, `seekend` and `truncate` are not available.                              

## Old Documentation

Old documentation link: https://gzipjl.readthedocs.io/en/latest/
