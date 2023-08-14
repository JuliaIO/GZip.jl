using GZip
using Documenter

makedocs(
    sitename = "GZip.jl",
    modules = [GZip],
    authors = "JuliaIO and contributors",
    format = Documenter.HTML(; assets = String[]),
    pages = [
        "GZip" => "index.md",
        "Reference" => "reference.md",
    ],
)

deploydocs(repo = "github.com/JuliaIO/GZip.jl", devbranch = "master")
