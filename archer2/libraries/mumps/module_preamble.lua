-- MUMPS preamble

family("mumps")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")
depends_on("metis/5.1.0")
depends_on("parmetis/4.0.3")
depends_on("scotch/6.1.0")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "MUMPS version " .. productLevel .. "\n"
local help2 = "For details of MUMPS on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/mumps/"

help ( help1 .. help2 .. help3 )

