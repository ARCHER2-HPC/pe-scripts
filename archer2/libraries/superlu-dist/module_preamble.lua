-- SuperLU-DIST preamble

family("superlu_dist")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")
depends_on("metis/5.1.0")
depends_on("parmetis/4.0.3")

-- This is introspection; may want to set explicitly.

local productName =  myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "SuperLU_DIST version " .. productLevel .. "\n"
local help2 = "For details of SuperLU_DIST on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/superlu/"

help ( help1 .. help2 .. help3 )

