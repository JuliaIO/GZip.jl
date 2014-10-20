using GZip
using Base.Test

if VERSION < v"0.3-"
    macro test_throws(a,b)
        :( Base.Test.@test_throws($b) )
    end
end

include(joinpath(Pkg.dir("GZip"),"test", "gzip_test.jl"))
