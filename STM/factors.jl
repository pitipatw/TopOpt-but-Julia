
begin
function getPhi(ϵ::Float64)
    ϕ = clamp(0.65+ 0.25*(ϵ-0.002)/0.003, 0.65 , 0.9)
    return ϕ
end



"""
get beta_n
input node score and output beta for capacity calculation
"""
function getBetaN(score::Dict{Int64,Float64})
    dict_of_betan = Dict{Int64,Float64}()
    for (k,v) in score
        if v == 0.
            dict_of_betan[k] = 1.0
        elseif v == 1.
            dict_of_betan[k] = 0.8
        elseif v == 2.
            dict_of_betan[k] = 0.6
        end
    end
    return dict_of_betan
end

"""
boundary strut = 1 
0.75
worst = 0.4
"""
function getBetaS(StrutLoc::Int64, StrutType::Int64, StrutCrit::Int64)
    if StrutLoc == 0 
        betaS= 0.4
    else
        if StrutType ==0
            betaS = 1.0
        else
            if StrutCrit != 0
                betaS = 0.40
            else 
                betaS = 0.75
            end
        end
    end

return betaS
end

"""
get BetaC
"""
function getBetaC(A1::Float64, A2::Float64)
    #a bit unclear
    #betaC = 1.0 is conservative
    betaC = 1.0
    return betaC
end

"""
"""
function getStrutLoc(connected_elements::Vector{Int64}, node_score::Dict{Int64,Float64})
    #check if the node is a boundary node
    #if it is, then it is a boundar
end
    
    """
    """
function getStrutType(connected_elements::Vector{Int64}, node_score::Dict{Int64,Float64})
    #check if the node is a boundary node
    #if it is, then it is a boundar
end

"""
"""
end