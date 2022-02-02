-- Patch up cray-hdf5-parallel
-- Handle PE_ENV correctly to set pkgconfig stuff

prereq_any("PrgEnv-cray", "PrgEnv-gnu", "PrgEnv-aocc")

depends_on("cray-hdf5-parallel/1.12.0.7")

-- Help section

help ( "Kludge-o-matic for cray-hdf5-parallel" )


-- EPCC FUNCTIONS

-- Return currently loaded compiler environment (CRAYCLANG, GNU, or AOCC)

function epccCompilerEnv()

  local compiler = "NONE"
  local pe = os.getenv("PE_ENV") or "NONE"

  if (pe == "CRAY") then
    compiler = "CRAYCLANG"
  elseif (pe == "GNU")  then
    compiler = "GNU"
  elseif (pe == "AOCC") then
    compiler = "AOCC"
  else
    error("No compiler environment available")
  end

  return compiler

end

-- Return currently loaded compiler version major.minor

function epccCompilerVersion()

  local version = nil
  local pe = epccCompilerEnv()

  if (pe == "CRAYCLANG") then
    version = os.getenv("CRAY_CC_VERSION") or nil
  elseif (pe == "GNU") then
    version = os.getenv("GNU_VERSION") or nil
  elseif (pe == "AOCC") then
    version = os.getenv("CRAY_AOCC_VERSION") or nil
  end

  local _, _, major, minor, patch = string.find(version, "(%d+)%.(%d+)%.(%d+)")

  return major .. "." .. minor

end

-- For relevant product, return a list of available compiler versions
-- A sorted list of numbers is returned (may be empty), e.g.,
-- "9.3 10.2"

function epccProductAvailableVersions(productRoot)

  require("lfs")

  local pe = epccCompilerEnv()
  local vlist = {}

  for file in lfs.dir(productRoot) do
    if (lfs.attributes(productRoot .. "/" .. file, "mode") == "directory") then
      local _, _, version = string.find(file, "(%d+%.%d+)")
      if (version ~= nil) then
        table.insert(vlist, tonumber(version))
      end
    end
  end

  table.sort(vlist)

  return vlist

end


local productName = "hdf5-parallel"
local productLevel = os.getenv("CRAY_HDF5_PARALLEL_VERSION")

local sharedRoot = "/opt/cray/pe"

-- Cray integration via pkgconfig
-- Compiler environment and currently loaded compiler version

local compilerEnv = epccCompilerEnv()
local compilerVersion = epccCompilerVersion()

-- If the currently loaded compiler version is not available,
-- look for the most recent previous version...

local productRoot = pathJoin(sharedRoot, productName, productLevel)
local productRootEnv = pathJoin(productRoot, compilerEnv)

local vlist = {}
local genCompiler = nil

vlist = epccProductAvailableVersions(productRootEnv)

if (#vlist == 0) then

  -- Fail
  error("No installations available for " .. compilerEnv)

else

  -- What's the most recent version in the list <= loaded compiler

  for _, candidate in pairs(vlist) do
    if (candidate <= tonumber(compilerVersion)) then
      genCompiler = tostring(candidate)
    end
  end

end

-- Set compiler-dependent information

if (genCompiler == nil) then
  error("Package not supported in the loaded compiler version")
else
  -- OK, can now set up

  local productPath = pathJoin(productRootEnv, genCompiler)

  -- Set variables for root of installation (both "_DIR" and "_ROOT"
  -- are made available)

  -- prepend_path("HDF5_PARALLEL_DIR",  productPath)
  -- prepend_path("HDF5_PARALLEL_ROOT", productPath)

  -- pkgconfig location

  local pkgconfig = pathJoin(productPath, "lib/pkgconfig")
  prepend_path("PE_" .. compilerEnv .. "_FIXED_PKGCONFIG_PATH", pkgconfig)

end

