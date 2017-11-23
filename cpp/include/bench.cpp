
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <assert.h>
#include <time.h>

#include "bench.h"

static char *get_flag_string(BenchmarkFlags flags) {
  static const size_t SZ = 8192;
  static char str[SZ];

  memset(str, 0, sizeof(str));

  if (!flags) {
    return str;
  }

  strncat(str, "[", SZ);

  if (flags & BENCH_FAILED) {
    strncat(str, "FAILED", SZ);
  }

  strncat(str, "]", SZ);
  return str;
}

static const char *get_parallel_string(int parallel) {
  static const char *yes = "true";
  static const char *no = "false";
  return parallel ? yes : no;
}

int _bench_write_header(BenchContext ctxt) {
  char *line;
  time_t rawtime;
  if (!ctxt->file) {
    return -1;
  }

  time(&rawtime);
  asprintf(&line, "Suite %s started at %s", ctxt->name, ctime(&rawtime));

  fwrite(line, sizeof(char), strlen(line), ctxt->file);
  free(line);

  return 0;
}

int _bench_write_benchmark(BenchContext ctxt, struct benchmark *benchmark) {
  char *line;
  struct timeval *diff = &benchmark->diff;

  if (!ctxt->file) {
    return -1;
  }
  asprintf(&line, "%s\t%s\t%s\t%s\t%ld.%06ld\n",
      benchmark->name,
      benchmark->system,
      get_parallel_string(benchmark->parallel),
      benchmark->input,
      (long)diff->tv_sec,
      (long)diff->tv_usec);

  fwrite(line, sizeof(char), strlen(line), ctxt->file);
  fflush(ctxt->file);
  free(line);

  return 0;
}

int _bench_write_footer(BenchContext ctxt) {
  assert(ctxt->file);

  // TODO think of a sensible footer to write.
  return 0;
}

BenchContext bench_init(const char *suite) {
  struct bench_context *b;
  char *filename;

  b = (struct bench_context *)malloc(sizeof(struct bench_context));
  memset(b, 0, sizeof(struct bench_context));

  strncpy(b->name, suite, NAMESZ);

  asprintf(&filename, "%s.benchmark", suite);
  FILE *f = fopen(filename, "w");
  assert(f);

  b->file = f;
  _bench_write_header(b);

  free(filename);

  return (BenchContext)b;
}

int bench_start(BenchContext ctxt, const char *testname,
    const char *system,
    const char *input,
    int parallel) {

  if (ctxt->num_benchmarks == MAX_BENCHMARKS) {
    return -1;
  }

  // only one benchmark allowed at a time for a given context
  if (ctxt->active_benchmark) {
    return -1;
  }

  ctxt->active_benchmark = (struct benchmark *)malloc(sizeof(struct benchmark));
  memset(ctxt->active_benchmark, 0, sizeof(struct benchmark));

  strncpy(ctxt->active_benchmark->name, testname, NAMESZ);
  strncpy(ctxt->active_benchmark->system, system, NAMESZ);
  strncpy(ctxt->active_benchmark->input, input, NAMESZ);
  ctxt->active_benchmark->parallel = parallel;

  // start the test.
  gettimeofday(&ctxt->active_benchmark->before, 0);
  return 0;
}

int bench_start(BenchContext ctxt, const char *testname) {
  return bench_start(ctxt, testname, "", "", 0);
}

int bench_stop(BenchContext ctxt) {
  if (ctxt->active_benchmark) {
    gettimeofday(&ctxt->active_benchmark->after, 0);

    timersub(&ctxt->active_benchmark->after, &ctxt->active_benchmark->before,
        &ctxt->active_benchmark->diff);

    // commit the benchmark and set the context state to inactive.
    ctxt->benchmarks[ctxt->num_benchmarks] = ctxt->active_benchmark;
    ctxt->num_benchmarks++;
    ctxt->active_benchmark = NULL;

    return 0;
  }

  return -1;
}

void bench_flush(BenchContext ctxt) {
  for (int i = 0; i < ctxt->num_benchmarks; i++) {
    if (!ctxt->benchmarks[i]->flushed) {
      _bench_write_benchmark(ctxt, ctxt->benchmarks[i]);
      ctxt->benchmarks[i]->flushed = 1;
    }
  }
}

void bench_setflags(BenchContext ctxt, BenchmarkFlags flags) {
  if (ctxt->num_benchmarks == 0 && !ctxt->active_benchmark) {
    return;
  }

  struct benchmark *b = ctxt->active_benchmark ?
    ctxt->active_benchmark : ctxt->benchmarks[ctxt->num_benchmarks - 1];
  b->flags = flags;
}

int bench_commit(BenchContext ctxt) {
  bench_flush(ctxt);
  _bench_write_footer(ctxt);
  fclose(ctxt->file);

  for (int i = 0; i < ctxt->num_benchmarks; i++) {
    free(ctxt->benchmarks[i]);
  }
  free(ctxt);

  return 0;
}
