-- PETSc preamble

family("petsc")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

depends_on("cray-hdf5-parallel")
depends_on("hypre/HYPRE_VERSION_TAG")
depends_on("mumps/MUMPS_VERSION_TAG")
depends_on("superlu/SUPERLU_VERSION_TAG")
depends_on("superlu-dist/SUPERLU_DIST_VERSION_TAG")


-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "PETSc version " .. productLevel .. "\n"
local help2 = "For details of PETSc on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/petsc/"

help ( help1 .. help2 .. help3 )

