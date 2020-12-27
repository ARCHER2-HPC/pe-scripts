/* Archer2 Metis install smoke test
 * (c) The University of Edinburgh 2020 */

/* The problem is taken from Figure 3 in the Metis manual. */

#include <stdio.h>
#include <metis.h>

#define NVTXS  15
#define NCON    1
#define MEDGES 22
#define NPARTS  2

int main(int argc, char ** argv) {

  int ierr = 0;

  idx_t nvtxs = NVTXS;
  idx_t ncon = NCON;
  idx_t nparts = NPARTS;
  
  idx_t xadj[NVTXS+1] = {0, 2, 5, 8, 11, 13, 16, 20, 24, 28, 31, 33, 36, 39,
			 42, 44};
  idx_t adjncy[2*MEDGES] = { 1, 5, 0, 2, 6, 1, 3, 7, 2, 4, 8, 3, 9, 0, 6, 10,
			     1, 5, 7, 11, 2, 6, 8, 12, 3, 7, 9, 13, 4, 8, 14,
			     5, 11, 6, 10, 12, 7, 11, 13, 8, 12, 14, 9, 13};

  idx_t vwgt[NVTXS];
  idx_t vsize[NVTXS];
  idx_t adjwgt[2*MEDGES];
  real_t tpwgts[NPARTS*NCON];
  real_t ubvec[NCON];
  idx_t  options[METIS_NOPTIONS];

  /* Output */

  idx_t objval;
  idx_t part[NVTXS];
  int   iret;

  /* Input */

  for (int iv = 0; iv < NVTXS; iv++) {
    vwgt[iv] = 1;
    vsize[iv] = 1;
  }

  for (int ie = 0; ie < 2*MEDGES; ie++) {
    adjwgt[ie] = 1;
  }

  for (int ic = 0; ic < NCON; ic++) {
    ubvec[ic] = 1.001;
    for (int ip = 0; ip < NPARTS; ip++) {
      tpwgts[ip*NCON+ic] = 1.0/NPARTS;
    }
  }
  
  /* Options nb. default are -1 */

  iret = METIS_SetDefaultOptions(options);
  
  iret = METIS_PartGraphRecursive(&nvtxs, &ncon, xadj, adjncy,
                                  vwgt, vsize, adjwgt, &nparts, tpwgts,
                                  ubvec, options, &objval, part);

  if (iret != METIS_OK) ierr = -1;
  
  return ierr;
}
