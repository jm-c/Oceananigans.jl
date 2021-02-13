struct PCGSolver{A, S}
        architecture :: A
            settings :: S
end

function PCGSolver(;arch=arch, 
                   grid=nothing, 
                   boundary_conditions=nothing,
                   parameters=parameters)
          
          bcs=boundary_conditions
          if isnothing(boundary_conditions)
           bcs   = parameters.Template_field.boundary_conditions
          end

          if isnothing(grid)
            grid  = parameters.Template_field.grid
          end

          maxit = parameters.maxit
          if isnothing(parameters.maxit)
            maxit = grid.Nx*grid.Ny*grid.Nz
          end

          tol = parameters.tol
          if isnothing(parameters.tol)
             tol   = 1.e-13
          end

          tf = parameters.Template_field
          if isnothing(parameters.Template_field)
            tf = CenterField(arch, grid)
          end
          a_res = similar(tf.data);a_res.=0.
          q     = similar(tf.data)
          p     = similar(tf.data)
          z     = similar(tf.data)
          r     = similar(tf.data)
          RHS   = similar(tf.data)
          x     = similar(tf.data)

          if parameters.PCmatrix_function == nothing
            # preconditioner not provided, use the Identity matrix
            PCmatrix_function(x) = ( return x )
          else
            PCmatrix_function = parameters.PCmatrix_function
          end
          M(x) = ( PCmatrix_function(x) )

          ii=grid.Hx:grid.Nx+grid.Hx-1
          ji=grid.Hy:grid.Ny+grid.Hy-1
          ki=grid.Hz:grid.Nz+grid.Hz-1
          dotproduct(x,y)  = mapreduce((x,y)->x*y, + , x[ii,ji,ki], y[ii,ji,ki])
          norm(x)          = ( mapreduce((x)->x*x, + , x[ii,ji,ki]   ) )^0.5

          Amatrix_function = parameters.Amatrix_function
          A(x) = ( Amatrix_function(a_res,x,arch,grid,bcs); return  a_res )

          reference_pressure_solver = nothing
          if haskey(parameters, :reference_pressure_solver )
            reference_pressure_solver = parameters.reference_pressure_solver
          end
          settings = (q=q, 
                      p=p,
                      z=z,
                      r=r,
                      x=x,
                    RHS=RHS,
                    bcs=bcs, 
                   grid=grid,
                      A=A,
                      M=M,
                  maxit=maxit,
                    tol=tol,
                dotprod=dotproduct,
                   norm=norm,
                   arch=arch,
  reference_pressure_solver=reference_pressure_solver,
          )

   return PCGSolver(arch, settings)
end

function solve_poisson_equation!(solver::PCGSolver,RHS,x)
#
# Alg - see Fig 2.5 The Preconditioned Conjugate Gradient Method in
#                    "Templates for the Solution of Linear Systems: Building Blocks for Iterative Methods"
#                    Barrett et. al, 2nd Edition. 
#
#     given 
#        linear Preconditioner operator M as a function M()
#        linear A matrix operator A as a function A()
#        a dot product function norm()
#        a right-hand side b
#        an initial guess x
#
#        local vectors: z, r, p, q
#
#     β  = 0
#     r .= b-A(x)
#     i  = 0
#
#     loop: 
#      if i > MAXIT 
#       break
#      end
#      z = M( r )
#      ρ    .= dotprod(r,z)
#      p = z+β*p
#      q = A(p)
#      α=ρ/dotprod(p,q)
#      x=x.+αp
#      r=r.-αq
#      if norm2(r) < tol
#       break
#      end
#      i=i+1
#      ρⁱᵐ1 .= ρ
#      β    .= ρⁱᵐ¹/ρ
#
      sset       = solver.settings
      z, r, p, q = sset.z, sset.r, sset.p, sset.q
      A          = sset.A
      M          = sset.M
      maxit      = sset.maxit
      tol        = sset.tol
      dotprod    = sset.dotprod
      norm       = sset.norm

      β    = 0.
      r   .= RHS .- A(x)
      i    = 0
      ρ    = 0
      ρⁱᵐ¹ = 0

      while true
       if i > maxit
        break
       end
       z    .= M(r)
       ρ     = dotprod(z,r)
       if i == 0
        p   .= z
       else
        β    = ρ/ρⁱᵐ¹
        p   .= z .+ β .* p
       end
       q    .= A(p)
       α     = ρ/dotprod(p,q)
       x    .= x .+ α .* p
       r    .= r .- α .* q
       if norm(r) <= tol
        break
       end
       i     = i+1
       ρⁱᵐ¹  = ρ
      end
#==
#     No preconditioner verison
      i    = 0
      r   .= RHS .- A(x)
      p   .= r
      γ    = dotprod(r,r)
      while true
       if i > maxit
        break
       end
       q   .= A(p)
       α    = γ/dotprod(p,q)
       x   .= x .+ α .* p
       r   .= r .- α .* q
       println("Solver ", i," ", norm(r) )
       if norm(r) <= tol
        break
       end
       γ⁺   = dotprod(r,r)
       β    = γ⁺/γ
       p   .= r .+ β .* p
       γ    = γ⁺
       i    = i+1
      end
==#
      ## println("PCGSolver ", i," ", norm(r) )

      fill_halo_regions!(x, sset.bcs, sset.arch, sset.grid)
      return x, norm(r)
end

function Base.show(io::IO, solver::PCGSolver)
        print(io, "Oceanigans compatible preconditioned conjugate gradient solver.\n")
        print(io, " Problem size = "  , size(solver.settings.q) ) 
        print(io, "\n Boundary conditions = "  , solver.settings.bcs  ) 
        print(io, "\n Grid = "  , solver.settings.grid  ) 
  return nothing
end