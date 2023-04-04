using DrWatson
@quickactivate "COVID-19 modelling"

# Here you may include files from the source directory
include(srcdir("dummy_src_file.jl"))

include(srcdir("data_loading.jl"))

data = data_processing("Nigeria")

filter_data_by_date(data, Date(2021, 3, 1), 30)

println(
"""
Currently active project is: $(projectname())

Path of active project: $(projectdir())

Have fun with your new project!

You can help us improve DrWatson by opening
issues on GitHub, submitting feature requests,
or even opening your own Pull Requests!
"""
)

a, b = 2, 3
v = rand(5)
method = "linear"
r, y = fakesim(a, b, v, method)

params = @strdict a b v method

allparams = Dict(
    "a" => [1, 2], # it is inside vector. It is expanded.
    "b" => [3, 4],
    "v" => [rand(5)],     # single element inside vector; no expansion
    "method" => "linear", # not in vector = not expanded, even if naturally iterable
)

dicts = dict_list(allparams)

function makesim(d::Dict)
    @unpack a, b, v, method = d
    r, y = fakesim(a, b, v, method)
    fulld = copy(d)
    fulld["r"] = r
    fulld["y"] = y
    return fulld
end

for (i, d) in enumerate(dicts)
    f = makesim(d)
    wsave(datadir("simulations", "sim_$(i).jld2"), f)
end

savename(params)
savename(dicts[1], "jld2")
readdir(datadir("simulations"))

for (i, d) in enumerate(dicts)
    f = makesim(d)
    @tagsave(datadir("simulations", savename(d, "jld2")), f)
end

firstsim = readdir(datadir("simulations"))[1]

wload(datadir("simulations", firstsim))

using DataFrames

df = collect_results(datadir("simulations"))