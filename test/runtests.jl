using StripRTF
using Test

function do_testfile(f::AbstractString)
    @info "TEST FILE \"$f\""
    rtf = read(joinpath(@__DIR__, "rtf", f * ".rtf"), String)
    txt = replace(read(joinpath(@__DIR__, "text", f * ".txt"), String), "\r\n" => "\n")
    if length(txt) < 100
        @test striprtf(rtf) == txt
    else
        ok = striprtf(rtf) == txt
        @test ok # omit long output on failures
    end
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
        do_testfile(f)
    end
end

@testset "other tests" begin
    # non-breaking space
    rtf = raw"{\rtf1\ansi{This is some {\b bold} text with non\~breaking\~spaces.\par}}"
    @test striprtf(rtf) == "This is some bold text with non\u00a0breaking\u00a0spaces.\n"
end
