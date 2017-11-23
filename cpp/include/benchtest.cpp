
#include <unistd.h>

#include "bench.h"

int main() {
  BenchContext b = bench_init("dummy_test");
  bench_start(b, "sleep_test");

  sleep(1);

  bench_stop(b);
  bench_setflags(b, BENCH_FAILED);

  bench_commit(b);

  return 0;
}
