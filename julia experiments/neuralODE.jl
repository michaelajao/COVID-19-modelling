using DifferentialEquations, SciMLSensitivity, Zygote, Plots, Random, DiffEqFlux, Flux

Random.seed!(1000);

function SEIR!(du, u, p, t)
    S, E, I, R = u
    β, σ, γ = p
    N = S + E + I + R
    du[1] = -β * S * I / N
    du[2] = β * S * I / N - σ * E
    du[3] = σ * E - γ * I
    du[4] = γ * I
end

N = 250_000_000
train_time = 50.0

# Set parameters
β = 0.4 # transmission rate
σ = 1 / 5 # incubation period (5 days)
γ = 1 / 10 # recovery period (10 days)
p = [β, σ, γ]

# Set initial conditions
S0 = N - data[1]
E0 = data[1] * 10
I0 = data[1]
R0 = 0
u0 = [S0, E0, I0, R0]

# Set time span and solve using DifferentialEquations.jl
tspan = (0.0, 100.0)
δt = 1


solver = Rodas5()
prob = ODEProblem(SEIR!, u0, tspan, p)
sol = solve(prob, solver, saveat=δt)


function plot_sol(sol, xlabel, ylabel, labels)
    plot(sol, xlab=xlabel, ylab=ylabel, label=labels, lw=3)
end

plot_sol(sol, "Time", "Proportion", ["S" "E" "I" "R"])
savefig("Figures/SEIR.png")


foi1 = FastDense(1, 1, relu, bias=false)
p1_ = Float64.(initial_params(foi1))
length(p1_)

function seir_ude(u, p_, t, foi)
    S, E, I, R = u
    β, σ, γ = p
    λ = foi([I], p_)[1]
    dS = -λ * S * I / N
    dE = λ * S * I / N - σ * E
    dI = λ * E - γ * I
    dR = λ * I
    [dS, dI, dE, dR]
end;

tspan_train = (0, train_time)
seir_ude1 = (u, p_, t) -> seir_ude(u, p_, t, foi1)
prob_ude1 = ODEProblem(seir_ude1,
    u0,
    tspan_train,
    p1_);


function predict(θ, prob)
    Array(solve(prob,
        solver;
        u0=u0,
        p=θ,
        saveat=δt,
        sensealg=InterpolatingAdjoint(autojacvec=ReverseDiffVJP())))
end;

function loss(θ, prob)
    pred = predict(θ, prob)
    cpred = abs.(N * diff(pred[3, :]))
    Flux.poisson_loss(cpred, float.(data)), cpred
end;

loss(prob_ude1.p, prob_ude1);

const losses1 = []
callback1 = function (p, l, pred)
    push!(losses1, l)
    numloss = length(losses1)
    if numloss % 10 == 0
        display("Epoch: " * string(numloss) * " Loss: " * string(l))
    end
    return false
end;

res_ude1 = DiffEqFlux.sciml_train((θ) -> loss(θ, prob_ude1),
    p1_,
    cb=callback1);

res_ude1.minimizer, losses1[end]

plot(losses1, xaxis=:log, xlabel="Iterations", ylabel="Loss", legend=false)

prob_ude1_fit = ODEProblem(seir_ude1, u0, tspan, res_ude1.minimizer)
sol_ude1_fit = solve(prob_ude1_fit, solver, saveat=δt)
scatter(sol, label=["True Susceptible" "True Infected" "True Recovered"], title="Fitted true model")
plot!(sol_ude1_fit, label=["Estimated Susceptible" "Estimated Infected" "Estimated Recovered"])

Imax = maximum(tsdata[2, :])
Igrid = 0:0.01:0.5
λ = [foi1([I], res_ude1.minimizer)[1] for I in Igrid]
scatter(Igrid, λ, xlabel="Proportion of population infected, I", ylab="Force of infection, λ", label="Neural network prediction")
Plots.abline!(p[1], 0, label="True value")
Plots.vline!([Imax], label="Upper bound of training data")


#multi-layer perception
Random.seed!(1234)
nhidden = 4
foi2 = FastChain(FastDense(1, nhidden, relu),
    FastDense(nhidden, nhidden, relu),
    FastDense(nhidden, nhidden, relu),
    FastDense(nhidden, 1, relu))
p2_ = Float64.(initial_params(foi2))
length(p2_)

seir_ude2 = (u, p_, t) -> seir_ude(u, p_, t, foi2)
prob_ude2 = ODEProblem(seir_ude2,
    u0,
    tspan_train,
    p2_);

const losses2 = []
callback2 = function (p, l, pred)
    push!(losses2, l)
    numloss = length(losses2)
    if numloss % 10 == 0
        display("Epoch: " * string(numloss) * " Loss: " * string(l))
    end
    return false
end;

res_ude2 = DiffEqFlux.sciml_train((θ) -> loss(θ, prob_ude2),
    p2_,
    cb=callback2);

losses1[end], losses2[end]

prob_ude2_fit = ODEProblem(seir_ude2, u0, tspan, res_ude2.minimizer)
sol_ude2_fit = solve(prob_ude2_fit, solver, saveat=δt)
scatter(sol, label=["True Susceptible" "True Infected" "True Recovered"], title="Fitted UDE model")
plot!(sol_ude2_fit, label=["Estimated Susceptible" "Estimated Infected" "Estimated Recovered"])


λ = [foi2([I], res_ude2.minimizer)[1] for I in Igrid]
scatter(Igrid, λ, xlabel="Proportion of population infected, i", ylab="Force of infection, λ", label="Neural network prediction")
Plots.abline!(p[1], 0, label="True value")
Plots.vline!([Imax], label="Upper bound of training data")