-- PETSc preamble

family("petsc")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

depends_on("epcc-cray-hdf5-parallel/1.12.0.3")
depends_on("hypre/2.18.0")
depends_on("mumps/5.3.5")
depends_on("superlu/5.2.2")
depends_on("superlu-dist/6.4.0")


-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "PETSc version " .. productLevel .. "\n"
local help2 = "For details of PETSc on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/petsc/"

help ( help1 .. help2 .. help3 )

