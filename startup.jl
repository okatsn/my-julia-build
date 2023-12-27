# [Automatically start with Julia](https://kristofferc.github.io/OhMyREPL.jl/latest/installation/#Automatically-start-with-Julia.)
# TerminalPager:
# - https://ronisbr.github.io/TerminalPager.jl/dev/
# - https://discourse.julialang.org/t/ann-terminalpager-jl-v0-5-0/104122
# !!! note "Clean volume to make the modification of `startup.jl` take effect"
#     This file (startup.jl) is located in .julia, which is mounted as "volume". Therefore,
#     you should delete container and volume of this or a container that uses `okatsn/my-julia-space`.
#
# !!! note "Also update Project.toml of that container"
#     When a container uses `startup.jl` of `okatsn/my-julia-space`, the packages (e.g., OhMyREPL)
#     should also be added to the Project.toml in the `WORKSPACE_DIR` for `startup.jl` to work
#     as expected.
atreplinit() do repl
    try
        @eval using OhMyREPL, TerminalPager, OkStartUp
    catch e
        @warn "error in startup.jl (okatsn/my-julia-space)" e
    end
end # mkdir -p $HOME/.julia/config && cp startup.jl "$_"
