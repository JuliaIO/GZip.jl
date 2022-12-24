using GZip
using Documenter

DocMeta.setdocmeta!(GZip, :DocTestSetup, :(using GZip); recursive = true)

makedocs(;
    modules = [GZip],
    authors = "JuliaIO and contributors",
    repo = "https://github.com/JuliaIO/GZip.jl/blob/{commit}{path}#{line}",
    sitename = "GZip.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://JuliaIO.github.io/GZip.jl",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "Loading Drivers" => "drivers.md",
        "High Level API" => "highlevel.md",
        "Low Level API" => "lowlevel.md",
        "Troubleshooting" => "troubleshooting.md",
    ],
)

deploydocs(; repo = "github.com/JuliaIO/GZip.jl", devbranch = "master")
