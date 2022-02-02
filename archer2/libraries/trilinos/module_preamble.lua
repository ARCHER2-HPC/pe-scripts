-- Trilinos preamble

family("trilinos")

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

depends_on("glm/0.9.9.6")
depends_on("boost/1.72.0")
depends_on("matio/1.5.18")
depends_on("mumps/5.3.5")
depends_on("superlu/5.2.2")
depends_on("superlu-dist/6.4.0")
depends_on("epcc-cray-hdf5-parallel/1.12.0.3")
depends_on("epcc-cray-netcdf-hdf5parallel")

-- This is introspection; may want to set explicitly.

local productName = myModuleName()
local productLevel = myModuleVersion()

-- Help section

local help1 = "Trilinos version " .. productLevel .. "\n"
local help2 = "For details of Trilinos on ARCHER2 see:  \n"
local help3 = "https://docs.archer2.ac.uk/software-libraries/trilinos/"

help ( help1 .. help2 .. help3 )

