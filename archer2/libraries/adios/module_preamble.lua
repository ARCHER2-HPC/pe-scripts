-- Adios v1 preamble
-- Note Adios does not integrate with the compiler wrappers
-- see https://docs.archer2.ac.uk/software-libraries/adios/

family("adios")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")
depends_on("epcc-cray-hdf5-parallel/1.12.0.3")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "Adios version " .. productLevel .. "\n"
local help2 = "For details of Adios on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/adios/"

help ( help1 .. help2 .. help3 )

