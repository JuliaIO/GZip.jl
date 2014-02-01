test_path = joinpath(Pkg.dir("GZip"),"test")
for test_file in readdir(test_path)
    include(joinpath(test_path, test_file))
end

