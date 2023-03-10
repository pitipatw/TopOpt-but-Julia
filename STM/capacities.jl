"""
calculate strut capacity
"""
function strutCapacity(betaC::Float64, betaS::Float64,fc′::Float64, Acs::Float64)
    fce = 0.85*betaC*betaS*fc′  # Concrete stress limit
    return 0.75*fce * Acs
end

"""
calculate tie capacity
"""
function tieCapacity(fy::Float64, Ats::Float64)
    return 0.75*fy * Ats
end

"""
calculate node capacity
"""
function nodeCapacity(betaC::Float64, betaS::Float64,fc′::Float64, Anz::Float64)
    fce = 0.85*betaC*betaS*fc′  # Concrete stress limit
    return 0.75*fce * Anz
end