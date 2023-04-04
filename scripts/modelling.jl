using .CovidModelling: data_processing, filter_by_date, plot_covid_cases

ng_data = data_processing("Nigeria")

filtered_ng = filter_by_date(ng_data, Date(2020, 3, 1), 100)

plot_covid_cases(filtered_ng, "Nigeria")


us_data = data_processing("US")

filtered_us = filter_by_date(us_data, Date(2020, 3, 1), 100)

plot_covid_cases(filtered_us, "United State")
using DifferentialEquations
using Plots

function seird!(du, u, p, t)
    β, σ, γ, μ = p
    S, E, I, R, D = u

    N = S + E + I + R + D

    du[1] = -β * S * I / N
    du[2] = β * S * I / N - σ * E
    du[3] = σ * E - γ * I - μ * I
    du[4] = γ * I
    du[5] = μ * I
end

β = 0.5
σ = 0.2
γ = 0.1
μ = 0.01
N = 1_000_000
E0 = 1
I0 = 10
R0 = 0
D0 = 0
S0 = N - E0 - I0 - R0 - D0
u0 = [S0, E0, I0, R0, D0]

p = [β, σ, γ, μ]
prob = ODEProblem(seird!, u0, tspan, p)
sol = solve(prob, Tsit5())

plot(sol, xlabel="Time (days)", ylabel="Population", label=["S" "E" "I" "R" "D"])
savefig("plots/SEIRD.png")



using NeuralPDE, Lux, CUDA, Random, ComponentArrays
using Optimization
using OptimizationOptimisers
import ModelingToolkit: Interval

@parameters t x y
@variables u(..)
Dxx = Differential(x)^2
Dyy = Differential(y)^2
Dt = Differential(t)
t_min = 0.0
t_max = 2.0
x_min = 0.0
x_max = 2.0
y_min = 0.0
y_max = 2.0

# 2D PDE
eq = Dt(u(t, x, y)) ~ Dxx(u(t, x, y)) + Dyy(u(t, x, y))

analytic_sol_func(t, x, y) = exp(x + y) * cos(x + y + 4t)
# Initial and boundary conditions
bcs = [u(t_min, x, y) ~ analytic_sol_func(t_min, x, y),
    u(t, x_min, y) ~ analytic_sol_func(t, x_min, y),
    u(t, x_max, y) ~ analytic_sol_func(t, x_max, y),
    u(t, x, y_min) ~ analytic_sol_func(t, x, y_min),
    u(t, x, y_max) ~ analytic_sol_func(t, x, y_max)]

# Space and time domains
domains = [t ∈ Interval(t_min, t_max),
    x ∈ Interval(x_min, x_max),
    y ∈ Interval(y_min, y_max)]

# Neural network
inner = 25
chain = Chain(Dense(3, inner, Lux.σ),
    Dense(inner, inner, Lux.σ),
    Dense(inner, inner, Lux.σ),
    Dense(inner, inner, Lux.σ),
    Dense(inner, 1))

strategy = GridTraining(0.05)
ps = Lux.setup(Random.default_rng(), chain)[1]
ps = ps |> ComponentArray |> gpu .|> Float64
discretization = PhysicsInformedNN(chain,
    strategy,
    init_params=ps)

@named pde_system = PDESystem(eq, bcs, domains, [t, x, y], [u(t, x, y)])
prob = discretize(pde_system, discretization)
symprob = symbolic_discretize(pde_system, discretization)

callback = function (p, l)
    println("Current loss is: $l")
    return false
end

res = Optimization.solve(prob, Adam(0.01); callback=callback, maxiters=2500)


prob = remake(prob, u0=res.u)
res = Optimization.solve(prob, Adam(0.001); callback=callback, maxiters=2500)

phi = discretization.phi
ts, xs, ys = [infimum(d.domain):0.1:supremum(d.domain) for d in domains]
u_real = [analytic_sol_func(t, x, y) for t in ts for x in xs for y in ys]
u_predict = [first(Array(phi(gpu([t, x, y]), res.u))) for t in ts for x in xs for y in ys]

using Plots
using Printf

function plot_(res)
    # Animate
    anim = @animate for (i, t) in enumerate(0:0.05:t_max)
        @info "Animating frame $i..."
        u_real = reshape([analytic_sol_func(t, x, y) for x in xs for y in ys],
            (length(xs), length(ys)))
        u_predict = reshape([Array(phi(gpu([t, x, y]), res.u))[1] for x in xs for y in ys],
            length(xs), length(ys))
        u_error = abs.(u_predict .- u_real)
        title = @sprintf("predict, t = %.3f", t)
        p1 = plot(xs, ys, u_predict, st=:surface, label="", title=title)
        title = @sprintf("real")
        p2 = plot(xs, ys, u_real, st=:surface, label="", title=title)
        title = @sprintf("error")
        p3 = plot(xs, ys, u_error, st=:contourf, label="", title=title)
        plot(p1, p2, p3)
    end
    gif(anim, "plots/3pde.gif", fps=10)
end

plot_(res)

CUDA.device()
