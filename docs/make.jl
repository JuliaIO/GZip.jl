using GZip
using Documenter

push!(LOAD_PATH,"../src/")

makedocs(
    sitename = "GZip.jl",
    modules = [GZip],
    authors = "JuliaIO and contributors",
    format = Documenter.HTML(; assets = String[]),
    pages = [
        "Home" => "index.md",
    ],
)

deploydocs(repo = "github.com/JuliaIO/GZip.jl", devbranch = "master")
