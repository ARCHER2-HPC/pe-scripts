/* A simple installation test for Matio. */

#include <stdio.h>
#include <matio.h>

int main(int argc, char ** argv) {

  int major, minor, release;

  Mat_GetLibraryVersion(&major, &minor, &release);
  printf("The Matio version is %d.%d.%d\n", major, minor, release);

  return 0;
}
