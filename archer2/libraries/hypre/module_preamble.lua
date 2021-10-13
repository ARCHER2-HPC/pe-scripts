-- HYPRE preamble

family("hypre")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "HYPRE version " .. productLevel .. "\n"
local help2 = "For details of HYPRE on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/hypre/"

help ( help1 .. help2 .. help3 )

