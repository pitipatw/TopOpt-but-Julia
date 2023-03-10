begin
"""
Functions used in FEM_truss.jl
"""

"""
function that adds the displacements of the free degrees of freedom to
the nodal displacements
-----------------------------------------------------------------------
dcomp(ndf,nnp)  = nodal displacements
d(neq,1)        = displacement at free degrees of freedom
id(ndf,nnp)     = equation numbers of degrees of freedom
ndf             = number of degrees of freedom per node
nnp             = number of nodal points
"""
function add_d2dcomp(dcomp::Matrix{Float64},d::Matrix{Float64},id::Matrix{Int8},ndf::Int64,nnp::Int64)

# loop over nodes and degrees of freedom
    for n=1:nnp
        for i=1:ndf
            
            # if it is a free dof then add the global displacement
            if id[i,n]>0       
                dcomp[i,n] = dcomp[i,n]+d[id[i,n]];
            end
        end
    end
    return dcomp
end
"""
# function that adds nodal forces to the global force vector
# -----------------------------------------------------------------------
# F(neq,1)        = global force vector
# f(ndf,nnp)      = prescribed nodal forces
# id(ndf,nnp)     = equation numbers of degrees of freedom
# ndf             = number of degrees of freedom per node
# nnp             = number of nodal points
"""
function add_loads_to_force(F::Any,f::Any,id::Array{Int8},ndf::Int64,nnp::Int64)
# loop over nodes and degrees of freedom
    for n = 1:nnp
        for i = 1:ndf
            
            # get the global equation number 
            M = id[i,n];  
            
            # if free degree of freedom, then add nodal load to global force 
            # vector
            if M > 0        
                F[M] = F[M]+f[i,n];
            end
        end
    end

    return F
end

"""
# function that adds element forces to the global force vector
# -----------------------------------------------------------------------
# F(neq,1)        = global force vector
# Fe(nee,1)       = element force vector
# LM(nee,nel)     = global to local map for the element
# nee             = number of element equations
"""
function addforce(F::Matrix{Float64},Fe::Matrix{Float64},LM::Matrix{Int8},nee::Int8)

    # loop over rows of Fe
    for i = 1:nee
        # get the global equation number for local equation i
        M = LM[i];    
        display(typeof(M))
        # if free dof (eqn number > 0) add to F vector
        if M > 0    
            F[M]=F[M]+Fe[i];
        end
    end
    return F
end

"""
# function that solves the equilibrium condition
# -----------------------------------------------------------------------
# K(neq,neq)      = global stiffness matrix
# Ke(nee,nee,1)   = element stiffness matrix
# LM(nee,nel)     = global to local map for the element
# nee             = number of element equations
"""
function addstiff(K::Array{Float64},Ke::Array{Float64},LM::Array{Int8},nee::Int8)

    # loop over rows of Ke
    for i = 1:nee
        
        # loop over columns of Ke
        for j = 1:nee                        
            
            Mr = LM[i];
            Mc = LM[j];
            
            if (Mr > 0 && Mc > 0)             
                # if equation #'s are non-zero add element contribution to the 
                # stiffness matrix
                K[Mr,Mc] = K[Mr,Mc]+Ke[i,j];
            end
        end
    end
    return K
end

"""
#  extracts element displacement vector from complete displacement vector
#------------------------------------------------------------------------
# dcomp(ndf,nnp)  = nodal displacements
# ien(nen,1)      = element connectivity
# ndf             = number of degrees of freedom per node
# nen             = number of element equations
#
# de(nen,1)       = element displacements
"""
function get_de_from_dcomp(dcomp::Any,ien::Any,ndf::Any,nen::Any)
    # This was zeros(nen,1) , but it has to be 4x1 or 2*nen, 1? 
    de = zeros(4,1);  
    # loop over number of element nodes
    for i = 1:nen
        
        # loop over number of degrees of freedom per node
        for j = 1:ndf
            # println(i,j)
            # get the local element number and place displacement in de
            leq     = (i-1)*ndf + j;   
            de[leq] = dcomp[j,ien[i]];
        end
    end
    return de
end

"""
# functions that performs the global to local mapping of equation numbers
# -----------------------------------------------------------------------
# id(ndf,nnp)     = equation numbers of degrees of freedom
# ien(nen,1)      = element connectivity
# ndf             = number of degrees of freedom per node
# nee             = number of element equations
# nen             = number of element equations
#
# LM(nee,1)       = global to local map for element
"""
function get_local_id(id::Any,ien::Any,ndf::Any,nee::Any,nen::Any)

    # initialize global-local mapping matrix
    LM  = zeros(nee,1);        

    # initialize local equation number counter
    k = 0;                      

    # loop over element nodes
    for i = 1:nen         
        
        # loop over degrees of freedom at each node
        for j = 1:ndf
            
            # update counter and prescribe global equation number
            k     = k+1;
            LM[k] = id[j,ien[i]];
        end
    end
    return LM
end

"""
# function that assembles the global load vector
# -----------------------------------------------------------------------
# id(ndf,nnp)     = equation numbers of degrees of freedom
# f(ndf,nnp)      = prescribed nodal forces
# g(ndf,nnp)      = prescribed nodal displacements
# ien(nen,nel)    = element connectivities
# Ke(nee,nee,nel) = element stiffness matrices
# ndf             = number of degrees of freedom per node
# nee             = number of element equations
# nel             = number of elements
# nen             = number of element equations
# neq             = number of equations
# nnp             = number of nodal points
#
# F(neq,1)        = global force vector
"""
function globalF(f::Any,g::Any,id::Array{Int8},ien::Any,Ke::Any,LM::Any,ndf::Any,nee::Any,nel::Any,nen::Any,neq::Any,nnp::Any) 
    # initialize
    F = zeros(neq,1);

    # Insert applied loads into F
    F = add_loads_to_force(F,f,id,ndf,nnp);

    # Compute forces from applied displacements (ds~=0) and insert into F
    Fse = zeros(nee,nel);  

    # loop over elements
    for i = 1:nel
        # get dse for current element
        dse  = get_de_from_dcomp(g,ien[:,i],ndf,nen);  
        
        # compute element force
        Fse[:,i] = -Ke[:,:,i] * dse;
        
        # assemble elem force into global force vector
        F        = addforce(F,Fse[:,i],LM[:,i],nee);     
    end

    return F
end

"""
# function that computes the global element stiffness matrix for a truss
# element
# -----------------------------------------------------------------------
# A(1,1)          = cross-sectional area of elements
# E(1,1)          = Young's modulus of elements
# ien(nen,1)      = element connectivity
# nee             = number of element equations
# nsd             = number of spacial dimensions
# xn(nsd,nnp)     = nodal coordinates
#
# Ke(nee,nee,1)   = global element stiffness matrix
# Te(nee,nee,1)   = global to local transformation matrix for element
"""
function Ke_truss(A::Any,E::Any,ien::Any,nee::Any,nsd::Any,xn::Any)

    # form vector along axis of element using nodal coordinates
    v = xn[:,ien[2]]-xn[:,ien[1]];

    # compute the length of the element
    Le = norm(v,2);

    # rotation of parent domain
    #   rot=[ cos(theta_x)  cos(theta_y)  cos(theta_z) ]'
    rot = v/Le;

    # local element stiffness matrix
    ke = E*A/Le*[  1  -1
        -1   1 ];

    # Transformation matrix: global to local coordinate system
    if (nsd == 2)   # 2D case
        
        # truss Te is nen x ndf*nen array
        Te = [ rot[1]  rot[2]       0       0
                    0       0  rot[1]  rot[2] ];
                
    elseif (nsd == 3)   # 3D case

        # Truss Te is nen x ndf*nen array
        Te = [ rot[1]  rot[2]  rot[3]       0       0       0  
                    0       0       0  rot[1]  rot[2]  rot[3] ];
    end

    # compute the global element stiffness matrix
    # Ke = zeros(nee,nee);
    Ke = Te'*ke*Te;

    return Ke,Te
end

"""
 function that numbers the unknown degrees of freedom (equations)
 -----------------------------------------------------------------------
 idb(ndf,nnp)    = 1 if the degree of freedom is prescribed, 0 otherwise
 ndf             = number of degrees of freedom per node
 nnp             = number of nodal points

 id(ndf,nnp)     = equation numbers of degrees of freedom
 neq             = number of equations (tot number of degrees of freedom)

 =======================================================================
"""
 function number_eq(idb::Array{Int8},ndf::Int8,nnp::Int8)
# initialize id and neq
    id  = zeros(Int8,ndf,nnp);  
    neq = 0;              

    # loop over nodes
    for n = 1:nnp
        
        # loop over degrees of freedom
        for i = 1:ndf
            if idb[i,n] == 0 
                
                # udate # of equations
                neq = neq + 1;      
                
                # if no prescribed displacement at dof i of node n
                #   => give an equation # different from 0
                id[i,n] = neq;      
                
            end
        end
    end
    return [id::Array{Int8}, neq]
end

"""
# function that performs post processing for truss elements
# -----------------------------------------------------------------------
# A(nel,1)        = cross-sectional area of elements
# d(neq,1)        = displacements at free degrees of freedom
# E(nel,1)        = Young's modulus of elements
# g(ndf,nnp)      = prescribed nodal displacements
# id(ndf,nnp)     = equation numbers of degrees of freedom
# ien(nen,nel)    = element connectivities
# Ke(nee,nee,nel) = element stiffness matrices
# ndf             = number of degrees of freedom per node
# nee             = number of element equations
# nel             = number of elements
# nen             = number of element equations
# nnp             = number of nodes
# Te(nee,nee,nel) = element transformation matrices
#
# dcomp(ndf,nnp)  = nodal displacements
# axial(nel,1)    = axial element forces
# stress(nel,1)   = element stresses
# strain(nel,1)   = element strains
# Fe(nee,nel)     = element forces

"""
function post_processing(A::Any,d::Any,E::Any,g::Any,id::Any,ien::Any,
    Ke::Any,ndf::Any,nee::Any,nel::Any,nen::Any,nnp::Any,Te::Any)

# get the total displacement of the structure in matrix form dcomp(nsd,nnp)
    dcomp = add_d2dcomp(g,d,id,ndf,nnp);

    # initalize evaluation of global element forces Fe, local element forces 
    # fe, axial forces, element stresses and strains
    Fe     = zeros(nee,nel);      
    de     = zeros(nee,nel);  
    fe     = zeros(1*nen,nel);  # element local force vector 
    axial  = zeros(nel,1); 
    stress = zeros(nel,1); 
    strain = zeros(nel,1); # element axial, stress, strain

    # loop over elements
        for i=1:nel
            
            # get the element displacaments
            de[:,i] = get_de_from_dcomp(dcomp,ien[:,i],ndf,nen);
            
            # compute the element forces
            Fe[:,i] = Ke[:,:,i]*de[:,i];

            # transform Fe to the local coordinate system
            fe[:,i] = Te[:,:,i]*Fe[:,i];

            # Compute the axial force, stress, strain
            axial[i] = fe[2,i] ;         # Use second entry for truss element
            stress[i] = axial[i]/A[i];   
            strain[i] = stress[i]/E[i];
        end
    return dcomp,axial,stress,strain,Fe
end


"""
# function that computes the reaction forces on the structure
# -----------------------------------------------------------------------
# idb(ndf,nnp)    = 1 if the degree of freedom is prescribed, 0 otherwise
# ien(nen,nel)    = element connectivities
# Fe(nee,nel)     = element forces
# ndf             = number of degrees of freedom per node
# nee             = number of element equations
# nel             = number of elements
# nen             = number of element equations
# nnp             = number of nodes
#
# Rcomp(ndf,nnp)  = nodal reactions
# idbr(ndf,nnp)   = 0 if the degree of freedom is prescribed,  otherwise
"""
function reactions(idb::Any,ien::Any,Fe::Any,ndf::Any,nee::Any,nel::Any,nen::Any,nnp::Any)

    # switch BC marker and number the equations for the reaction forces
    idbr       = 1 .- idb;  
    idr::Array{Int8},neqr = number_eq(idbr,ndf,nnp);

    # assemble reactions R from element force vectors Fe 
    R   = zeros(neqr,1);  
    for i = 1:nel
        LMR::Array{Int8} = get_local_id(idr,ien[:,i],ndf,nee,nen);
        R   = addforce(R,Fe[:,i],LMR,nee);
    end

    # organize the reactions in matrix array Rcomp(ndf,nnp)
    Rcomp = zeros(ndf,nnp);
    Rcomp = add_d2dcomp(Rcomp,R,idr,ndf,nnp);
    return [Rcomp,idr]
end

"""
# function that solves the equilibrium condition
# -----------------------------------------------------------------------
# F(neq,1)        = global force vector
# LM(nee,nel)     = global to local maps
# Ke(nee,nee,nel) = element stiffness matrices
# nee             = number of element equations
# nel             = number of elements
# neq             = number of equations

Output
 d(neq,1)        = displacements at free degrees of freedom
"""
function solveEQ(F::Any,LM::Any,Ke::Any,nee::Any,nel::Any,neq::Any) 

    K = zeros(neq,neq);   # Use 'sparse' for more efficient memory usage
    for i = 1:nel
        K = addstiff(K,Ke[:,:,i],LM[:,i],nee);
    end

    # solve the equlibrium
    d = K\F;

    return d 
end

end