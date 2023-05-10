using StripRTF
using Test

function testfile_matches(f::AbstractString)
    rtf = read(joinpath(@__DIR__, "rtf", f * ".rtf"), String)
    txt = read(joinpath(@__DIR__, "text", f * ".txt"), String)
    stripped = striprtf(rtf)
    @info "TEST FILE \"$f\""
    if length(txt) < 40 && stripped != txt
        @warn " -- EXPECTED \"$(escape_string(txt))\" BUT GOT \"$(escape_string(stripped))\""
    end
    return stripped == txt
end

@testset "test files" begin
    for f in [  "Example_text",
                "Speiseplan_KW_32-33_Eybl",
                "ansicpg1250",
                "bytes",
                "calcium_score",
                "encoding",
                "french",
                "hello",
                "hyperlinks",
                "issue_11",
                "issue_15",
                "issue_20",
                "issue_28",
                "issue_29_bad",
                "issue_29_good",
                "issue_37",
                "issue_38",
                "line_break_textedit_mac",
                "mac_textedit_hyperlink",
                "nested_table",
                "nutridoc",
                "sample_3",
                "simple_table",
                "test_line_breaks_google_docs",
                "unicode" ]
        @test testfile_matches(f)
    end
end
