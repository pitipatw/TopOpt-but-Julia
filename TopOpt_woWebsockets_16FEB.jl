using HTTP.WebSockets
using JSON
using TopOpt, LinearAlgebra, StatsFuns
using StaticArrays

#This is for visualization
using Makie, GLMakie
using TopOpt.TrussTopOptProblems.TrussVisualization: visualize
using ColorSchemes


node_points, elements, mats, crosssecs, fixities, load_cases = load_truss_json(joinpath(@__DIR__, "forTestStress"))

ndim, nnodes, ncells = length(node_points[1]), length(node_points), length(elements)
loads = load_cases["0"]
problem = TrussProblem(
    Val{:Linear}, node_points, elements, loads, fixities, mats, crosssecs
)
println("Inputs Pass Successfully!")

xmin = 0.0001 # minimum density
x0 = fill(0.1, ncells) # initial design
p = 4.0 # penalty
# V = 0.1 # maximum volume fraction


V = 0.4
solver = FEASolver(Direct, problem; xmin=xmin)
comp = TopOpt.Compliance(solver)

function obj(x)
    # minimize compliance
    return comp(PseudoDensities(x))
end
function constr(x)
    # volume fraction constraint
    return sum(x) / length(x) - V
end

# setting upmodel
m = Model(obj)
#add variable boundary (model , lb, ub)
addvar!(m, zeros(length(x0)), ones(length(x0)))
# add constrain
Nonconvex.add_ineq_constraint!(m, constr)

options = MMAOptions(; maxiter=1000, tol=Tolerance(; kkt=1e-4, f=1e-4))
TopOpt.setpenalty!(solver, p)
@time r = Nonconvex.optimize(
    m, MMA87(; dualoptimizer=ConjugateGradient()), x0; options=options
)

@show obj(r.minimizer)
@show constr(r.minimizer)
color_per_cell = [1*ones(trunc(Int, (length(x0)/4))) ;-0.5*ones(trunc(Int, length(x0)/4)) ;-0.2*ones(trunc(Int, length(x0)/4)) ;-100*ones(trunc(Int, length(x0)/4))]

#1968 elements
#color_per_cell = vec(100 * rand(Float64 , (1,1968)))
#color_per_cell = rand(Float64, 1968)
color_per_cell = TrussStress(solver)(PseudoDensities(r.minimizer))
Stress = TrussStress(solver)
color_per_cell2 = Stress(PseudoDensities(r.minimizer))
A = color_per_cell2 .>=0
B = color_per_cell2 .<0
C = A.-B
#color_per_cell = color_per_cell/maximum(color_per_cell)
cpc_boolean = color_per_cell.<0


fig = visualize(
    problem ; u = solver.u, topology=r.minimizer
    ,default_exagg_scale=0.0
    ,default_element_linewidth_scale = 6.0
    ,default_load_scale = 0.1
    ,default_support_scale = 0.1
    ,cell_colors = C
    ,colormap = ColorSchemes.Spectral_11
 )
Makie.display(fig)