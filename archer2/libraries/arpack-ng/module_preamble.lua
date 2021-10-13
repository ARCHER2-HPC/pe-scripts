-- ARPACK-NG preamble

family("arpack_ng")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

-- This is introspection; may want to set explicitly.

local productName =  myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "ARPACK-NG version " .. productLevel .. "\n"
local help2 = "For details of ARPACK on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/arpack/"

help ( help1 .. help2 .. help3 )

