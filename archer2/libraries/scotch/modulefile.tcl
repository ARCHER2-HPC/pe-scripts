#%Module
#

# This module file has been automatically generated

set shared_root TEMPLATE_INSTALL_ROOT
set module_root ${shared_root}/archer2-modules

set scotch_version TEMPLATE_SCOTCH_VERSION

source ${module_root}/archer-modules-tcl.lib
source ${module_root}/archer-pkgconfig-tcl.lib

# Clashes

conflict scotch

proc ModulesHelp { } {
  puts stderr "Scotch graph partitioning library version $::scotch_version"
  puts stderr "See https://docs.archer2.ac.uk/software-libraries/scotch/"
  puts stderr "Installed by: Kevin Stratford, EPCC"
  puts stderr "Date: TEMPLATE_TIMESTAMP\n"
}

set _module_name  [module-info name]
set sys           [uname sysname]

if { ! [ info exists env(PE_ENV) ] } {

  puts stderr "No programming environment available!"

} else {
  
  set lcName "scotch"
  set ucName [ string toupper $lcName ]

  set prod_level ${scotch_version}
  set prod_root ${shared_root}/libs/$lcName/$prod_level

  # Cray integration via pkgconfig
  # Compiler environment and currently loaded compiler version

  set compiler [ epccPrgEnvCompilerEnv ]
  set compiler_version_loaded [ epccPrgEnvCompilerVersion $compiler ]

  setenv PE_${ucName}_MODULE_NAME $lcName

  # Set package config path so pkgconfig can operate
  # OpenMP is not required.

  set_pkgconfig_paths $prod_root $ucName

  set pe_product_dir $prod_root
  set pe_pkgconfig_libs $lcName

  prepend-path PE_PKGCONFIG_LIBS $pe_pkgconfig_libs
  setenv PE_${ucName}_PKGCONFIG_LIBS  $pe_pkgconfig_libs

  # If the currently loaded compiler version is not available,
  # look for the most recent previous version...

  if { ! [ file isdirectory $pe_product_dir/$compiler ] } {
    puts stderr "Missing $pe_product_dir/$compiler"
    exit
  } else {

    # Is the current loaded compiler version available in $pe_product_dir ?
    # If not, is there a previous version available?

    set available [ epccProductAvailableVersions $pe_product_dir $compiler ]

    if { [ llength $available ] == 0 } {
      puts stderr "No compiler builds available in $pe_product_dir/$compiler !"
    } else {
 
      # What's the most recent version in the list <= loaded compiler
      foreach candidate [ lsort -real $available ] {
        if { $candidate <= $compiler_version_loaded } {
          set gen_compiler $candidate
        }
      }
    }
  } 

  # Set compiler-dependent information

  if { ! [ info exists gen_compiler ] } {
    puts stderr "$lcName cannot support the loaded compiler version"
    exit
  } else {
    set product_curpath $pe_product_dir/$compiler/$gen_compiler

    # Potential change while module is loaded not handled
    prepend-path PATH $product_curpath/bin
    prepend-path MANPATH $product_curpath/share/man  

    # Also non-volatile
    setenv ${ucName}_DIR ${product_curpath}  

    # load or remove paths
    if { ! [ module-info mode remove ] } {
      prepend-path PATH $product_curpath/lib
    } else {
      set oldpath $env(PATH)
      foreach mod [ split $oldpath ':' ] {
        if { [ expr [ lsearch [ split $mod '/' ] $lcName ] >= 0 ] } {
	  # This is mode remove so prepend is remove
          prepend-path PATH $mod
        } 
      }
    }
  }

}
