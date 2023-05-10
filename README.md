# StripRTF

The `StripRTF` module exports a single function, [`striprtf(text)`](@ref), that
strips all formatting from a string in [Rich Text Format (RTF)](https://en.wikipedia.org/wiki/Rich_Text_Format)
to yield "plain text".

This code is a Julia port of the Python [`striprtf` package](https://github.com/joshy/striprtf) by
Joshy Cyriac, which in turn is based on [code posted to StackOverflow](https://stackoverflow.com/questions/188545/regular-expression-for-extracting-text-from-an-rtf-string)
by Markus Jarderot and Gilson Filho.

## API

```jl
striprtf([out::IO,] text::AbstractString)
```

Given a string `text` in [Rich Text Format (RTF)](https://en.wikipedia.org/wiki/Rich_Text_Format),
returns a string of "plain text" with all of the RTF formatting removed.

If the optional `out` argument is supplied, the output is instead written
to this output `IO` stream, returning `out`.

## Example

```jl
julia> using StripRTF

julia> striprtf(raw"""
               {\rtf1\ansi{\fonttbl\f0\fswiss Helvetica;}\f0\pard
               This is some {\b bold} text.\par
               }""")
"This is some bold text.\n"
```
