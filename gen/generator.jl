using Clang.Generators
using Clang.Generators.JLLEnvs
using ZlibNG_jll

cd(@__DIR__)
options = load_options(joinpath(@__DIR__, "generator.toml"))
headers = ZlibNG_jll.artifact_dir .* ["/include/zlib-ng.h", "/include/zconf-ng.h"]

# run generator for all platforms
for target in JLLEnvs.JLL_ENV_TRIPLES
    @info "processing $target"

    options["general"]["output_file_path"] = joinpath(@__DIR__, "..", "src/lib", "$target.jl")

    # add compiler flags, e.g. "-DXXXXXXXXX"
    args = get_default_args()
    arch = JLLEnvs.get_arch(target)
    os = JLLEnvs.get_os(target)
    push!(args, "-DWITH_GZFILEOP")

    # create context
    ctx = create_context(headers, args, options)

    # run generator
    build!(ctx)
end
