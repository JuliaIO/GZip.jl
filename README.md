# GZip.jl: A Julia interface for gzip functions in zlib

This module provides a wrapper for the gzip related functions of
[zlib](http://zlib.net), a free, general-purpose, legally
unencumbered, lossless data-compression library. These functions
allow the reading and writing of gzip files.

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

## Notes

-   This interface is only for gzipped files, not the streaming zlib compression interface. Internally, it depends on/uses the streaming interface, but the gzip related functions are higher level functions pertaining to gzip files only.                                            
-   `GZipStream` is an implementation of `IO` and can be used virtually anywhere `IO` is used.
-   This implementation mimics the `IOStream` implementation, and should be a drop-in replacement for `IOStream`, with some caveats:
    -   `seekend` and `truncate` are not available
    -   `readuntil` is available, but is not very efficient. (But `readline` works fine.)                        
                                                                                                                 
In addition to [`open`](@ref), [`gzopen`](@ref), and [`gzdopen`](@ref), the following `IO`/`IOStream` functions are supported:                 
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
