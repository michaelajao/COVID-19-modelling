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
tspan = (0.0, 365.0)

p = [β, σ, γ, μ]
prob = ODEProblem(seird!, u0, tspan, p)
sol = solve(prob, Tsit5())

plot(sol, xlabel="Time (days)", ylabel="Population", label=["S" "E" "I" "R" "D"])
