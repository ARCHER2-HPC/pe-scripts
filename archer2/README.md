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



## Usage

From the directory one level above this, .e.g.,

```
$ bash ./archer2/tpsl/metis.sh --prefix=/work/y07/shared
```

## Build

For each package, a number of versions are compiled appropriate
for different programming environment.

## Modules

Modulefiles are installed to
```
/work/y07/shared/archer2-modules/modulefiles-cse-libs
```

## Package specifics (libraries formerly TPSL)

Some details for each package will appear here.

| Package      | Version  | Dependencies            | OpenMP? | MPI? |
|--------------|----------|-------------------------|---------|------|
| glm          | 0.9.9.6  | none                    | no      | no   |
| hypre        | 2.18.0   | none                    | -       | yes  |
| matio        | 1.5.18   | none                    | no      | no   |
| metis        | 5.1.0    | none                    | yes     | no   |
| mumps        | 5.2.1    | metis, parmetis, scotch |         | yes  |
| parmetis     | 4.0.3    | none                    | yes     | yes  |
| scotch       | 6.0.9    | none                    | no      | yes  |
| sundials     | tbc      | none                    | -       | -    |
| superlu      | 5.2.1    | blas                    | no      | no   |
| superlu-dist | 6.1.1    | metis, parmetis         | -       | yes  |


