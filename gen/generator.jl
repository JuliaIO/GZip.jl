using Clang.Generators
using Clang.Generators.JLLEnvs
using Zlib_jll

cd(@__DIR__)
options = load_options(joinpath(@__DIR__, "generator.toml"))
headers = "zlib.h"

# run generator for all platforms
for target in JLLEnvs.JLL_ENV_TRIPLES
    @info "processing $target"

    options["general"]["output_file_path"] = joinpath(@__DIR__, "..", "src/lib", "$target.jl")

    # add compiler flags, e.g. "-DXXXXXXXXX"
    args = get_default_args()
    arch = JLLEnvs.get_arch(target)
    os = JLLEnvs.get_os(target)
    if (arch == "aarch64" || arch == "x86_64" || arch == "powerpc64le") && (os != "windows")
        push!(args, "-DZ_WANT64")
    end

    # create context
    ctx = create_context(headers, args, options)

    # run generator
    build!(ctx)
end
