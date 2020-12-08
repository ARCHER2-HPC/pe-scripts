/* A simple Parmetis program as an installation smoke test.
 *
 * The problem is from the Parmetis manual.
 */

#include <stdio.h>
#include <mpi.h>
#include <parmetis.h>

#define NPROCS      3
#define NVTXS_LOCAL 5
#define NCON        1
#define NPARTS      2

int main(int argc, char ** argv) {

  int ierr = 0;
  int rank = 0;

  idx_t wgtflag = 0; /* vwgt and adjwgt will both be NULL */
  idx_t numflag = 0; /* C-style numbering will be used */
  idx_t ncon = NCON;
  idx_t nparts = NPARTS;
  
  idx_t xadj0[NVTXS_LOCAL+1] = {0, 2, 5,  8, 11, 13};
  idx_t xadj1[NVTXS_LOCAL+1] = {0, 3, 7, 11, 15, 18};
  idx_t xadj2[NVTXS_LOCAL+1] = {0, 2, 5,  8, 11, 13};

  idx_t adjncy0[13] = {1, 5, 0, 2, 6, 1, 3, 7, 2, 4, 8, 3, 9};
  idx_t adjncy1[18] = {0, 6, 10, 1, 5, 7, 11, 2, 6, 8, 12, 3, 7, 9, 13, 4, 8, 14};
  idx_t adjncy2[13] = {5, 11, 6, 10, 12, 7, 11, 13, 8, 12, 14, 9, 13};

  real_t tpwgts[NPARTS*NCON];
  real_t ubvec[NCON];
  idx_t options[METIS_NOPTIONS] = {0}; /* Defaults */

  idx_t vtxdist[NPROCS+1] = {0, 5, 10, 15};

  /* Output */

  idx_t edgecut;
  idx_t part[NVTXS_LOCAL];
  idx_t iret;

  /* Parallel */
  idx_t * xadj = NULL;
  idx_t * adjncy = NULL;
  MPI_Comm comm = MPI_COMM_WORLD;

  /* Start */

  MPI_Init(&argc, &argv);

  MPI_Comm_rank(comm, &rank);

  if (rank == 0) {
    xadj = xadj0;
    adjncy = adjncy0;
  }
  else if (rank == 1) {
    xadj = xadj1;
    adjncy = adjncy1;
  }
  else if (rank == 2) {
    xadj = xadj2;
    adjncy = adjncy2;
  }
  else {
    printf("Must run on exactly 3 MPI tasks\n");
    MPI_Abort(comm, -1);
  }

  for (int ic = 0; ic < NCON; ic++) {
    ubvec[ic] = 1.001;
    for (int ip = 0; ip < NPARTS; ip++) {
      tpwgts[ip*NCON+ic] = 1.0/NPARTS;
    }
  }
  
  iret = ParMETIS_V3_PartKway(vtxdist, xadj, adjncy, NULL, NULL, &wgtflag,
			      &numflag, &ncon, &nparts, tpwgts, ubvec,
			      options, &edgecut, part, &comm);
  {
    int ierr_local = 0;
    if (iret != METIS_OK) ierr_local = -1;
  
    MPI_Reduce(&ierr_local, &ierr, 1, MPI_INT, MPI_SUM, 0, comm);
  }
  MPI_Finalize();

  return ierr;
}
