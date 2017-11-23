#ifndef __BENCH_H__
#define __BENCH_H__

#include <stdio.h>
#include <sys/time.h>

#define NAMESZ              256
#define MAX_BENCHMARKS      1024

typedef unsigned BenchmarkFlags;

// Internal private structures.
struct benchmark {

  // Characteristics of a benchmark
  char name[NAMESZ];
  char system[NAMESZ];
  char input[NAMESZ];
  int parallel;

  struct timeval before;
  struct timeval after;
  struct timeval diff;

  unsigned flushed;
  BenchmarkFlags flags;
};

struct bench_context {
  char name[NAMESZ];
  FILE *file;

  size_t num_benchmarks;

  struct benchmark *active_benchmark;
  struct benchmark *benchmarks[MAX_BENCHMARKS];
};

// This is the opaque object passed to outside code.
typedef struct bench_context* BenchContext;

// Benchmark flags will be added here
enum BenchmarkFlagValue {
  BENCH_FAILED        = 0x1,
};

/**
 * Initialize a benchmark suite. This opens a file named ./`suite`-`date`.benchmark,
 * where `suite` is the provided suite name and `date` is the current UNIX time.
 * All subsequent benchmarking information is written to this file. The file is closed
 * when bench_stop() is called. Currently only a single benchmark can be open at a time.
 *
 * @param suite the suite name
 * @return 0 on success, -1 if an error occurred.
 */
BenchContext bench_init(const char *suite);

/**
 * Commit a benchmark. This closes the benchmark file and cleans up any state, allowing
 * a new benchmark to be started.
 *
 * @return 0 on sucess, -1 on error.
 */
int bench_commit(BenchContext ctxt);

/**
 * Start timing a benchmark. 
 * 
 * @param ctxt the context to use.
 * @param benchmark the name of the benchmark.
 * @return 0 on success, -1 if an error occurred.
 */
int bench_start(BenchContext ctxt, const char *benchmark);

int bench_start(BenchContext ctxt, const char *testname,
    const char *system,
    const char *input,
    int parallel);

/** 
 * End timing the current active benchmark
 *
 * @param ctxt the context to use.
 * @return 0 on success, -1 if an error occurred.
 */
int bench_stop(BenchContext ctxt);


/**
 * Flush benchmark information to the output file.
 *
 * @param ctxt the context to use.
 */
void bench_flush(BenchContext ctxt);

/**
 * Set flags for the last active benchmark if there is no current active
 * benchmark, or the active benchmark.
 *
 * @param ctxt the context to use.
 */
void bench_setflags(BenchContext ctxt, BenchmarkFlags flags);

#endif /** __BENCH_H__ */
