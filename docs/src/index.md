# GZip.jl \-\-- A Julia interface for gzip functions in zlib

::: {.module synopsis="Wrapper for gzip functions in zlib"}
GZip
:::

This module provides a wrapper for the gzip related functions of
([zlib](http://zlib.net/)), a free, general-purpose, legally
unencumbered, lossless data-compression library. These functions allow
the reading and writing of gzip files.

## Notes

> -   This interface is only for gzipped files, not the streaming zlib
>     compression interface. Internally, it depends on/uses the
>     streaming interface, but the gzip related functions are higher
>     level functions pertaining to gzip files only.
> -   `GZipStream`{.interpreted-text role="class"} is an implementation
>     of `IO`{.interpreted-text role="class"} and can be used virtually
>     anywhere `IO`{.interpreted-text role="class"} is used.
> -   This implementation mimics the `IOStream`{.interpreted-text
>     role="class"} implementation, and should be a drop-in replacement
>     for `IOStream`{.interpreted-text role="class"}, with some caveats:
>     -   `seekend`{.interpreted-text role="func"} and
>         `truncate`{.interpreted-text role="func"} are not available
>     -   `readuntil`{.interpreted-text role="func"} is available, but
>         is not very efficient. (But `readline`{.interpreted-text
>         role="func"} works fine.)

In addition to `open`{.interpreted-text role="func"},
`gzopen`{.interpreted-text role="func"} and `gzdopen`{.interpreted-text
role="func"}, the following `IO`{.interpreted-text
role="class"}/`IOStream`{.interpreted-text role="class"} functions are
supported:

> -   `close()`{.interpreted-text role="func"}
> -   `flush()`{.interpreted-text role="func"}
> -   `seek()`{.interpreted-text role="func"}
> -   `skip()`{.interpreted-text role="func"}
> -   `position()`{.interpreted-text role="func"}
> -   `eof()`{.interpreted-text role="func"}
> -   `read()`{.interpreted-text role="func"}
> -   `readuntil()`{.interpreted-text role="func"}
> -   `readline()`{.interpreted-text role="func"}
> -   `write()`{.interpreted-text role="func"}
> -   `peek()`{.interpreted-text role="func"}

Due to limitations in `zlib`, `seekend`{.interpreted-text role="func"}
and `truncate`{.interpreted-text role="func"} are not available.

## Functions

::: function
open(fname, \[gzmode, \[buf_size\]\])

Alias for `gzopen`{.interpreted-text role="func"}. This is not exported,
and must be called using `GZip.open`{.interpreted-text role="func"}.
:::

::: function
gzopen(fname, \[gzmode, \[buf_size\]\])

Opens a file with mode (default `"r"`), setting internal buffer size to
buf_size (default `Z_DEFAULT_BUFSIZE=8192`), and returns a the file as a
`GZipStream`{.interpreted-text role="class"}.

`gzmode` must contain one of

+-----+---------------------------+
| > r | > read                    |
+-----+---------------------------+
| > w | > write, create, truncate |
+-----+---------------------------+
| > a | > write, create, append   |
+-----+---------------------------+

In addition, gzmode may also contain

+-------+------------------------------------------------------+
| > x   | > create the file exclusively (fails if file exists) |
+-------+------------------------------------------------------+
| > 0-9 | > compression level                                  |
+-------+------------------------------------------------------+

and/or a compression strategy:

+-----+----------------------------+
| > f | > filtered data            |
+-----+----------------------------+
| > h | > Huffman-only compression |
+-----+----------------------------+
| > R | > run-length encoding      |
+-----+----------------------------+
| > F | > fixed code compression   |
+-----+----------------------------+

Note that `+` is not allowed in gzmode.

If an error occurs, `gzopen` throws a `GZError`{.interpreted-text
role="class"}
:::

::: function
gzdopen(fd, \[gzmode, \[buf_size\]\])

Create a `GZipStream`{.interpreted-text role="class"} object from an
integer file descriptor. See `gzopen`{.interpreted-text role="func"} for
`gzmode` and `buf_size` descriptions.
:::

::: function
gzdopen(s, \[gzmode, \[buf_size\]\])

Create a `GZipStream`{.interpreted-text role="class"} object from
`IOStream`{.interpreted-text role="class"} `s`.
:::

## Types

::: type
GZipStream(name, gz_file, \[buf_size, \[fd, \[s\]\]\])

Subtype of `IO`{.interpreted-text role="class"} which wraps a gzip
stream. Returned by `gzopen`{.interpreted-text role="func"} and
`gzdopen`{.interpreted-text role="func"}.
:::

::: type
GZError(err, err_str)

gzip error number and string. Possible error values:

  --------------------- ----------------------------------------
  `Z_OK`                No error

  `Z_ERRNO`             Filesystem error (consult `errno()`)

  `Z_STREAM_ERROR`      Inconsistent stream state

  `Z_DATA_ERROR`        Compressed data error

  `Z_MEM_ERROR`         Out of memory

  `Z_BUF_ERROR`         Input buffer full/output buffer empty

  `Z_VERSION_ERROR`     zlib library version is incompatible
                        with caller version
  --------------------- ----------------------------------------
:::
