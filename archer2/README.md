# Archer2 installation

The scripts in this directory lie alongside the build scripts
in `../pe-scripts` and are used to install packages in
appropriate locations.

There are a number of notable differences between what happens
here, and what is done by the standard `pe-scripts`.

1. Each package is intended to be built separately, and installed
in a separate location. Dependencies required for compilation are
expected to be provided by previously installed packages via the
module system.

2. Packages supporting OpenMP and compiled with and without OpenMP
and give rise to separate sets of libraries. Libraries built
against OpenMP should contain an `_mp` in their name. The appropriate
library is selected at compile/link determined by the presence or
absence of `-fopenmp` (or the apprpriate option).

There are two additional options implemented via `../sh/preamble.sh`. These
are
```
--modules   Use modules for dependency locations (default is prefix location).
--openmp    Use OpenMP (default is no OpenMP).
--shared    Build shared libraries (if supported). Default is static.
```

## Usage

From the directory one level above this, .e.g.,

```
$ bash ./archer2/libraries/metis/metis-build.sh --prefix=/work/y07/shared
```

which will install libraries to

```
${prefix}/libs/core
```

## Build

For each package, a number of versions are compiled appropriate
for different programming environment.

## Modules

Modulefiles are installed to
```
/work/y07/shared/archer2-lmod/libs/core
```

## Library modules (formerly TPSL)

Some details for each package appear in the respective directories.

### Post upgrade 2025

| Package      | Version  | Dependencies            | OpenMP? | MPI? |
|--------------|----------|-------------------------|---------|------|
| hypre        | 2.33.0   | none                    | yes     | yes  |
| metis        | 5.1.0    | none                    | yes     | no   |
| mumps        | 5.8.1    | metis, parmetis, scotch | yes     | yes  |
| parmetis     | 4.0.3    | none                    | yes     | yes  |
| scotch       | 7.0.10   | none                    | no      | yes  |
| superlu      | 7.0.1    | none                    | no      | no   |
| superlu-dist | 9.1.0    | metis, parmetis         | yes     | yes  |
| petsc        | 3.24.1   | metis, parmetis, scotch | no      | yes  |
|              |          | hypre, superlu[-dist]   |         |      |
|              |          | cray-hdf5-parallel      |         |      |
| slepc        | 3.24.0   | petsc                   | no      | yes  |

Note there is no MUMPS support in PETSc owing to problems arising from
the C++ link stage with MUMPs Fortran libraries.


### Post upgrade 2023

| Package      | Version  | Dependencies            | OpenMP? | MPI? |
|--------------|----------|-------------------------|---------|------|
| hypre        | 2.25.0   | none                    | yes     | yes  |
| matio        | 1.5.23   | none                    | no      | no   |
| metis        | 5.1.0    | none                    | yes     | no   |
| mumps        | 5.5.1    | metis, parmetis, scotch | yes     | yes  |
| parmetis     | 4.0.3    | none                    | yes     | yes  |
| scotch       | 7.0.3    | none                    | no      | yes  |
| sundials     | 4.1.0    | none                    | yes     | yes  |
| superlu      | 5.3.0    | none                    | no      | no   |
| superlu-dist | 8.1.2    | metis, parmetis         | yes     | yes  |


### Pre-upgrade 2023

| Package      | Version  | Dependencies            | OpenMP? | MPI? |
|--------------|----------|-------------------------|---------|------|
| glm          | 0.9.9.6  | none                    | no      | no   |
| hypre        | 2.18.0   | none                    | yes     | yes  |
| matio        | 1.5.18   | none                    | no      | no   |
| metis        | 5.1.0    | none                    | yes     | no   |
| mumps        | 5.3.5    | metis, parmetis, scotch | yes     | yes  |
| parmetis     | 4.0.3    | none                    | yes     | yes  |
| scotch       | 6.1. 0   | none                    | no      | yes  |
| sundials     | 4.1.0    | none                    | yes     | yes  |
| superlu      | 5.2.2    | none                    | no      | no   |
| superlu-dist | 6.4.0    | metis, parmetis         | yes     | yes  |


## Library modules (others via pe-scripts)

### Post upgrade 2023

| Package      | Version  | Dependencies               | OpenMP? | MPI? |
|--------------|----------|----------------------------|---------|------|
| adios        | PENDING  | cray-hdf5-parallel         | no      | yes  |
| boost        | 1.81.0   | none                       | no      | yes  |
| petsc        | 3.18.5   | superlu, superlu-dist,     | no      | yes  |
|              |          | metis, parmetis, scotch,   |         |      |
|              |          | mumps, hypre,              |         |      |
|              |          | cray-hdf5-parallel         |         |      |
| slepc        | 3.18.3   | petsc                      | no      | yes  |
| trilinos     | 13.4.1   | cray-hdf5-parallel         | yes     | yes  |
|              |          | cray-netcdf-hdf5parallel   |         |      |
|              |          | tpsl (bar hypre,sundials   |         |      |
|              |          | and glm) boost             |         |      |

### Pre upgrade 2023

| Package      | Version  | Dependencies               | OpenMP? | MPI? |
|--------------|----------|----------------------------|---------|------|
| adios        | 1.13.1   | cray-hdf5-parallel         | no      | yes  |
| boost        | 1.72.0   | none                       | no      | yes  |
| petsc        | 3.14.2   | superlu, superlu-dist,     | no      | yes  |
|              |          | metis, parmetis, scotch,   |         |      |
|              |          | mumps, hypre,              |         |      |
|              |          | cray-hdf5-parallel         |         |      |
| slepc        | 3.14.1   | petsc                      | no      | yes  |
| trilinos     | 12.18.1  | cray-hdf5-parallel         | yes     | yes  |
|              |          | cray-netcdf-hdf5parallel   |         |      |
|              |          | tpsl (bar hypre,sundials)  |         |      |
|              |          | boost                      |         |      |


## Library modules (other CSE)

| Package      | Version  | Dependencies               | OpenMP? | MPI? |
|--------------|----------|----------------------------|---------|------|
| arpack-ng    | 3.8.0    | none                       | no      | yes  |



## Other

See also https://github.com/PE-Cray/cpe-changelog
