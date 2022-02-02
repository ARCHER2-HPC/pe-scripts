-- xthi preamble

family("xthi")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "xthi version " .. productLevel .. "\n"
local help2 = "For details of scheduling on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/user-guide/scheduler"

help ( help1 .. help2 .. help3 )

