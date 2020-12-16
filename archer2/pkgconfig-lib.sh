#!/usr/bin/env bash

set -e

function pcPackageConfigFiles {

    # Run craypkg-gen and then patch up the results

    local prefix=${1} # pc files will be ${prefix}/lib/pkgconfig/*.pc
    local -n pc=${2}  # pcmap associative array
    
    module load craypkg-gen
    craypkg-gen -p ${prefix}

    printf "Generating updated pcfiles\n"
    
    local pcfiles="${prefix}/lib/pkgconfig"
    pcFileUpdate ${pcfiles} pc

}


function pcFileUpdate {

    local prefix=${1}    # Location of *.pc files
    local -n pchm=${2}   # pchashmap
    
    # If there are no .pc files, this is an error. Intentional.
    local files=($(ls ${prefix}/*.pc))
    
    for file in "${files[@]}"; do
	# For each pc file, rewrite in the correct form
	pcFileRefactor "${file}" pchm
    done

    # Remove _mp files from the list
    # Here we don't want an error if there is none

    IFS=" " read -r -a files_mp <<< "`ls ${prefix}/*_mp.pc 2>/dev/null`"

    for file_mp in "${files_mp[@]}"; do
	for i in "${!files[@]}"; do
	    if [[ ${files[i]} = ${file_mp} ]]; then
		unset 'files[i]'
	    fi
	done
    done
    
    printf "Generating top-level package pcfile\n"
    
    pcFileWritePackageFile "${prefix}/${pchm[name]}.pc" pchm files
}

function pcFileWritePackageFile {

    # Aggregate pc file for package as a whole

    local pcnew=${1}      # Path to new file
    local -n pchash=${2}  # pc hash
    local -n reqs=${3}    # requirements

    local ucName=`echo ${pchash[name]} | tr '[:lower:]' '[:upper:]' `
    
    local pe_omp_requires=""
    local omp_requires=""

    if test ${pchash[has_openmp]} -eq 1; then
      pe_omp_requires="PE_${ucName}_OMP_REQUIRES=\n"
      omp_requires="\${PE_${ucName}_OMP_REQUIRES}"
    fi
    
    printf "# Package ${pchash[name]} pc file\n" > ${pcnew}
    printf "\n" >> ${pcnew}
    printf "${pe_omp_requires}\n" >> ${pcnew}
    printf "Name: ${pchash[name]}\n" >> ${pcnew}
    printf "Version: ${pchash[version]}\n" >> ${pcnew}
    printf "Description: ${pchash[description]}\n" >> ${pcnew}

    printf "Requires: " >> ${pcnew}
    
    for req in "${reqs[@]}"; do
	lib=`basename ${req%.pc}`
	printf "${lib}${omp_requires}" >> ${pcnew}
    done

    printf "\n" >> ${pcnew}
}

function pcFileRefactor {

    local pcfile=${1}       # Full path to existing pc file from craypkg-gen
    local -n pchash=${2}    # pc hash

    # We overrite any existing file (but not yet)

    pcnew="`dirname ${pcfile}`/tmp-pkgconfig.pc"
    
    printf "# pkg-config file automatically generated\n" > ${pcnew}
    printf "\n" >> ${pcfile}
    printf "Name: %s\n" "${pchash[name]}" >> ${pcnew}
    printf "Version: %s\n" "${pchash[version]}" >> ${pcnew}
    printf "Description: %s\n" "${pchash[description]}" >> ${pcnew}

    requires="`pkg-config --print-requires ${pcfile}`"
    requires_private="`pkg-config --print-requires-private ${pcfile}`"

    printf "\n" >> ${pcnew}
    printf "Requires: %s\n" "${requires}" >> ${pcnew}
    printf "Requires.private: %s\n" "${requires_private}" >> ${pcnew}
    printf "\n" >> ${pcnew}

    # Variable definitions

    var_prefix="`pkg-config --print-variables ${pcfile} | grep prefix`"
    var_libdir="`pkg-config --print-variables ${pcfile} | grep libdir`"
    var_includedir="`pkg-config --print-variables ${pcfile} | grep includedir`"

    value_prefix="`pkg-config --variable=${var_prefix} ${pcfile}`"
    value_libdir="-L\${${var_prefix}}/lib"
    value_includedir="-I\${${var_prefix}}/include"

    printf "${var_prefix}= %s\n" "${value_prefix}" >> ${pcnew}
    printf "${var_libdir}= %s\n" "${value_libdir}" >> ${pcnew}
    printf "${var_includedir}= %s\n" "${value_includedir}" >> ${pcnew} 

    # Additional variables:

    printf "\n" >> ${pcnew}
    printf "cray_as_needed=\n" >> ${pcnew}
    printf "cray_no_as_needed=\n" >> ${pcnew}
    printf "\n" >> ${pcnew}

    # Cflags:

    cflags="\${${var_includedir}}"
    printf "Cflags: %s\n" "${cflags}" >> ${pcnew}

    # Libs: separate into an array for individual archives
    # IFS is the internal field separator: a space

    IFS=" " read -r -a libs <<< "`pkg-config --libs-only-l ${pcfile}`"

    printf "Libs: \${${var_libdir}} " >> ${pcnew}

    for lib in "${libs[@]}"; do
      printf "\${cray_as_needed}%s\${cray_no_as_needed} " "${lib}" >> ${pcnew}
    done

    if [[ -n ${pchash[extra_libs]} ]]; then
      lib=${pchash[extra_libs]}
      printf "\${cray_as_needed}%s\${cray_no_as_needed}" "${lib}" >> ${pcnew}
    fi

    printf "\n" >> ${pcnew}

    # Libs.private
    # No very easy way to get at these.
    # 'pkg-config --libs-only-l --static' is too much.
    # So slurp in the whole line and extract anything matching "-lname"
    # Will not catch continuation markers.

    printf "Libs.private: " >> ${pcnew}

    IFS=" " read -r -a libs_line <<< "`grep Libs.private ${pcfile}`"

    for word in "${libs_line[@]}"; do
	[[ $word = -l* ]] && printf "%s " "${word}" >> ${pcnew}
    done

    printf "\n" >> ${pcnew}

    # Validate the new file
    pkg-config --validate ${pcnew}
    mv ${pcnew} ${pcfile}
}
