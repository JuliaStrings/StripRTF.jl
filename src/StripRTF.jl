"""
The `StripRTF` module exports a single function, [`striprtf(text)`](@ref), that
strips all formatting from a string in [Rich Text Format (RTF)](https://en.wikipedia.org/wiki/Rich_Text_Format)
to yield "plain text".

This code is a Julia port of the Python [`striprtf` package](https://github.com/joshy/striprtf) by
Joshy Cyriac, which in turn is based on [code posted to StackOverflow](https://stackoverflow.com/questions/188545/regular-expression-for-extracting-text-from-an-rtf-string)
by Markus Jarderot and Gilson Filho.
"""
module StripRTF

import StringEncodings
export striprtf

const destinations = Set{String}([
    "aftncn","aftnsep","aftnsepc","annotation","atnauthor","atndate","atnicn","atnid",
    "atnparent","atnref","atntime","atrfend","atrfstart","author","background",
    "bkmkend","bkmkstart","blipuid","buptim","category","colorschememapping",
    "colortbl","comment","company","creatim","datafield","datastore","defchp","defpap",
    "do","doccomm","docvar","dptxbxtext","ebcend","ebcstart","factoidname","falt",
    "fchars","ffdeftext","ffentrymcr","ffexitmcr","ffformat","ffhelptext","ffl",
    "ffname","ffstattext","file","filetbl","fldinst","fldtype",
    "fname","fontemb","fontfile","fonttbl","footer","footerf","footerl","footerr",
    "footnote","formfield","ftncn","ftnsep","ftnsepc","g","generator","gridtbl",
    "header","headerf","headerl","headerr","hl","hlfr","hlinkbase","hlloc","hlsrc",
    "hsv","htmltag","info","keycode","keywords","latentstyles","lchars","levelnumbers",
    "leveltext","lfolevel","linkval","list","listlevel","listname","listoverride",
    "listoverridetable","listpicture","liststylename","listtable","listtext",
    "lsdlockedexcept","macc","maccPr","mailmerge","maln","malnScr","manager","margPr",
    "mbar","mbarPr","mbaseJc","mbegChr","mborderBox","mborderBoxPr","mbox","mboxPr",
    "mchr","mcount","mctrlPr","md","mdeg","mdegHide","mden","mdiff","mdPr","me",
    "mendChr","meqArr","meqArrPr","mf","mfName","mfPr","mfunc","mfuncPr","mgroupChr",
    "mgroupChrPr","mgrow","mhideBot","mhideLeft","mhideRight","mhideTop","mhtmltag",
    "mlim","mlimloc","mlimlow","mlimlowPr","mlimupp","mlimuppPr","mm","mmaddfieldname",
    "mmath","mmathPict","mmathPr","mmaxdist","mmc","mmcJc","mmconnectstr",
    "mmconnectstrdata","mmcPr","mmcs","mmdatasource","mmheadersource","mmmailsubject",
    "mmodso","mmodsofilter","mmodsofldmpdata","mmodsomappedname","mmodsoname",
    "mmodsorecipdata","mmodsosort","mmodsosrc","mmodsotable","mmodsoudl",
    "mmodsoudldata","mmodsouniquetag","mmPr","mmquery","mmr","mnary","mnaryPr",
    "mnoBreak","mnum","mobjDist","moMath","moMathPara","moMathParaPr","mopEmu",
    "mphant","mphantPr","mplcHide","mpos","mr","mrad","mradPr","mrPr","msepChr",
    "mshow","mshp","msPre","msPrePr","msSub","msSubPr","msSubSup","msSubSupPr","msSup",
    "msSupPr","mstrikeBLTR","mstrikeH","mstrikeTLBR","mstrikeV","msub","msubHide",
    "msup","msupHide","mtransp","mtype","mvertJc","mvfmf","mvfml","mvtof","mvtol",
    "mzeroAsc","mzeroDesc","mzeroWid","nesttableprops","nextfile","nonesttables",
    "objalias","objclass","objdata","object","objname","objsect","objtime","oldcprops",
    "oldpprops","oldsprops","oldtprops","oleclsid","operator","panose","password",
    "passwordhash","pgp","pgptbl","picprop","pict","pn","pnseclvl","pntext","pntxta",
    "pntxtb","printim","private","propname","protend","protstart","protusertbl","pxe",
    "result","revtbl","revtim","rsidtbl","rxe","shp","shpgrp","shpinst",
    "shppict","shprslt","shptxt","sn","sp","staticval","stylesheet","subject","sv",
    "svb","tc","template","themedata","title","txe","ud","upr","userprops",
    "wgrffmtfilter","windowcaption","writereservation","writereservhash","xe","xform",
    "xmlattrname","xmlattrvalue","xmlclose","xmlname","xmlnstbl",
    "xmlopen",
    ])

# Translation of some special characters.
const specialchars = Dict{String,String}([
    "par" => "\n",
    "sect" => "\n\n",
    "page" => "\n\n",
    "line" => "\n",
    "tab" => "\t",
    "emdash" => "\u2014",
    "endash" => "\u2013",
    "emspace" => "\u2003",
    "enspace" => "\u2002",
    "qmspace" => "\u2005",
    "bullet" => "\u2022",
    "lquote" => "\u2018",
    "rquote" => "\u2019",
    "ldblquote" => "\u201C",
    "rdblquote" => "\u201D",
    "row" => "\n",
    "cell" => "|",
    "nestcell" => "|",
])

const PATTERN = r"\\([a-z]{1,32})(-?\d{1,10})?[ ]?|\\'([0-9a-f]{2})|\\([^a-z])|([{}])|[\r\n]+|(.)"i

const HYPERLINKS = r"(\{\\field\{\s*\\\*\\fldinst\{.*?HYPERLINK\s(\".*?\")\}{2}\s*\{.*?\s+(.*?)\}{2}\}?)"i

_replace_hyperlinks(text::String) = replace(text, HYPERLINKS => s"\1(\2)")

"""
    striprtf([out::IO,] text::AbstractString)

Given a string `text` in [Rich Text Format (RTF)](https://en.wikipedia.org/wiki/Rich_Text_Format),
returns a string of "plain text" with all of the RTF formatting removed.

If the optional `out` argument is supplied, the output is instead written
to this output `IO` stream, returning `out`.
"""
striprtf(out::IO, text::AbstractString) = _striprtf(out, String(text))
striprtf(text::AbstractString) = String(take!(striprtf(IOBuffer(), text)))

function _striprtf(out::IO, text::String)
    text = _replace_hyperlinks(text)
    stack = Tuple{Int,Bool}[]
    ignorable = false       # Whether this group (and all inside it) are "ignorable".
    ucskip = 1              # Number of ASCII characters to skip after a unicode character.
    curskip = 0             # Number of ASCII characters left to skip
    encoder = out
    for match in eachmatch(PATTERN, text)
        word, arg, hex, char, brace, tchar = match.captures
        if brace !== nothing
            curskip = 0
            if brace == "{"
                # Push state
                push!(stack, (ucskip,ignorable))
            elseif brace == "}"
                # Pop state
                if isempty(stack)
                    # sample_3.rtf throws an IndexError because of stack being empty.
                    # don't know right now how this could happen, so for now this is
                    # a ugly hack to prevent it
                    ucskip = 0
                    ignorable = true
                else
                    ucskip,ignorable = pop!(stack)
                end
            end
        elseif char !== nothing # \x (not a letter)
            curskip = 0
            ch = only(char)
            if ch == '~'
                !ignorable && (flush(encoder); print(out, '\ua0'))
            elseif ch in "{}\\\n\r"
                !ignorable && (flush(encoder); print(out, char))
            elseif ch == '*'
                ignorable = true
            end
        elseif word !== nothing # \foo
            curskip = 0
            if word in destinations
                ignorable = true
            elseif word == "ansicpg" # http://www.biblioscape.com/rtf15_spec.htm#Heading8
                codepage = parse(Int, arg)
                if codepage != 65001 && codepage != 0
                    encoder = StringEncodings.StringEncoder(out, "UTF-8", "windows-$codepage")
                end
            elseif ignorable
                nothing
            elseif word in keys(specialchars)
                flush(encoder); print(out, specialchars[word])
            elseif word == "uc"
                ucskip = parse(Int, arg)
            elseif word == "u"
                # because of https://github.com/joshy/striprtf/issues/6
                if arg !== nothing
                    c = parse(Int, arg)
                    c < 0 && (c += 0x10000)
                    flush(encoder); print(out, Char(c))
                end
                curskip = ucskip
            end
        elseif hex !== nothing # \'xx
            if curskip > 0
                curskip -= 1
            elseif !ignorable
                byte = parse(UInt8, hex, base=16)
                write(encoder, byte)
            end
        elseif tchar !== nothing
            if curskip > 0
                curskip -= 1
            elseif !ignorable
                flush(encoder); print(out, tchar)
            end
        end
    end
    encoder !== out && close(encoder)
    return out
end

end
