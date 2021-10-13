-- SLEPc preamble

family("slepc")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")
depends_on("petsc/3.14.2")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "SLEPc version " .. productLevel .. "\n"
local help2 = "For details of SLEPc on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/slepc/"

help ( help1 .. help2 .. help3 )

