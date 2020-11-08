#include <time.h>
#include <sys/mman.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <assert.h>

static uint64_t
diff_ns(struct timespec* end, struct timespec* start) {
  return (end->tv_sec - start->tv_sec) * 1000000000 \
    + (end->tv_nsec - start->tv_nsec);
}

static void
measure_memset(size_t kb) {
  const size_t byte = kb * 1024;
  volatile char* ptr = malloc(byte);
  mlock((char*)ptr, byte);
  uint64_t time_ns = 0;

  for (int i = 0; i < 1000; i++) {
    struct timespec start, end;
    ptr[0] = 0;
    ptr[byte/2] = 0;
    ptr[byte-1] = 0;

    clock_gettime(CLOCK_MONOTONIC, &start);
    memset ((char*)ptr, 1, byte);
    clock_gettime(CLOCK_MONOTONIC, &end);
    time_ns += diff_ns(&end, &start);

    assert(ptr[0] == 1);
    assert(ptr[byte/2] == 1);
    assert(ptr[byte-1] == 1);
  }

  munlock((char*)ptr, byte);
  free ((char*)ptr);

  printf ("NativeMemset,%zu,%lu\n", kb, time_ns);
}

int
main (void)
{
  printf ("type,dataSize[KB],time[ns]\n");
  for (int kb = 1; kb <= 8192; kb *= 2) {
    measure_memset(kb);
  }
  return 0;
}
