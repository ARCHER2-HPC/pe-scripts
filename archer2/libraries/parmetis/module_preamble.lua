-- Parmetis preamble

family("parmetis")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")
depends_on("metis/5.1.0")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "Parmetis version " .. productLevel .. "\n"
local help2 = "For details of Metis and Parmetis on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/metis/"

help ( help1 .. help2 .. help3 )

