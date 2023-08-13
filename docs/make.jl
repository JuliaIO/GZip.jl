using GZip
using Documenter

DocMeta.setdocmeta!(GZip, :DocTestSetup, :(using GZip); recursive = true)

makedocs(
    sitename = "GZip.jl",
    modules = [GZip],
    authors = "JuliaIO and contributors",
    format = Documenter.HTML(; assets = String[]),
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(; repo = "github.com/JuliaIO/GZip.jl", devbranch = "master")
