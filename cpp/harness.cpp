// clang++-3.8 -O3 -Iinclude -I../weld_rt/cpp harness.cpp oom.ll ../weld_rt/cpp/runtime.cpp ../weld_rt/cpp/dict.cpp ../weld_rt/cpp/vb.cpp ../weld_rt/cpp/merger.cpp ../weld_rt/cpp/inline.cpp -o run
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include <algorithm>
#include <sys/time.h>

#include "include/common.h"

using namespace nvl;

void print();
int32_t *get_global();

struct input {
  int64_t in;
  int32_t nworkers;
  int64_t mem_limit;
};

struct output {
  int64_t out;
  int64_t run_id;
  int64_t errno;
};

// Pack arguments into this structure, in the order
// they appear in your NVL function.
struct arguments {
  vec<i32> _1;
  vec<i32> _2;
  vec<float> _3;
  vec<float> _4;
  vec<float> _5;
  vec<i32> _6;
  vec<float> _7;
  // vec<i32> _3;
};

struct k {
  i32 _1;
  i32 _2;
};

struct v {
  float _1;
  float _2;
  float _3;
  float _4;
  float _5;
  float _6;
};

struct kv {
  k key;
  v value;
};

extern "C" {
  output *run(struct input *in);
}

extern "C" void weld_runtime_init();

// Setup and call run() here.

int main(int argc, char **argv) {
  const unsigned LEN = atoi(argv[1]);
  const unsigned MOD = atoi(argv[3]);
  const unsigned PRINT = atoi(argv[4]);

  /*
  vec<vec<uint8_t> > v1 = make_vec<vec<uint8_t> >(LEN);
  for (int i = 0; i < LEN; i++) {
    v1.ptr[i] = make_vec<uint8_t>(1);
    v1.ptr[i].ptr[0] = i;
  }
  */
  assert(LEN % MOD == 0);
  int copies_per_key = LEN / MOD;
  vec<i32> v1 = make_vec<i32>(LEN);
  vec<i32> v2 = make_vec<i32>(LEN);
  vec<float> v3 = make_vec<float>(LEN);
  vec<float> v4 = make_vec<float>(LEN);
  vec<float> v5 = make_vec<float>(LEN);
  vec<i32> v6 = make_vec<i32>(LEN);
  vec<float> v7 = make_vec<float>(LEN);
  for (int i = 0; i < LEN; i++) {
    int next_key = i / copies_per_key;
    v1.ptr[i] = 0; // next_key >> 16;
    v2.ptr[i] = next_key; // next_key & ((1 << 16) - 1);
    *(int *)(v3.ptr + i) = rand();
    *(int *)(v4.ptr + i) = rand();
    *(int *)(v5.ptr + i) = rand();
    v6.ptr[i] = (rand() % 2) == 0 ? 19980901 : 19980902;
    *(int *)(v7.ptr + i) = rand();
  }
  std::random_shuffle(v2.ptr, v2.ptr + LEN);

  struct arguments a;
  a._1 = v1;
  a._2 = v2;
  a._3 = v3;
  a._4 = v4;
  a._5 = v5;
  a._6 = v6;
  a._7 = v7;
  // a._3 = v1;

  struct input in;
  in.in = (int64_t)&a;
  in.nworkers = atoi(argv[2]);
  in.mem_limit = 200000000000L;

  // getchar();
  struct timeval start, end, diff;
  gettimeofday(&start, 0);
  // printf("running...\n");
  weld_runtime_init();
  output res = *run(&in);
  // printf("err: %ld\n", res.errno);
  vec<kv> vec_res = *((vec<kv>*)res.out);
  gettimeofday(&end, 0);
  timersub(&end, &start, &diff);
  printf("%ld.%06ld\n", (long)diff.tv_sec, (long)diff.tv_usec);
  // printf("len: %ld\n", vec_res.size);
  /*
  for (int i = 0; i < vec_res.size; i++) {
    printf("len_inner: %lld\n", vec_res.ptr[i].size);
    // printf("data: %d\n", vec_res.ptr[i].ptr[0]);
  }
  */
  /*
  for (int i = 0; i < vec_res.size; i++) {
    // if (vec_res.ptr[i]._1 != vec_res.ptr[i]._2) {
    if (PRINT) {
      printf("%d->%d (index %d)\n", vec_res.ptr[i]._1, vec_res.ptr[i]._2, i);
    // }
    }
  }
  */
  /*
  for (int i = 0; i < LEN; i++) {
    for (int j = 0; j < v1.ptr[i].size; j++) {
      printf("%d (%d), ", vec_res.ptr[i].ptr[j], v1.ptr[i].ptr[j]);
    }
    printf("\n");
  }
  */

  /*
  gettimeofday(&start, 0);
  i32 sum = 0;
  for (int i = 0; i < LEN; i++) {
    for (int j = 0; j < v1.ptr[i].size; j++) {
      sum += v1.ptr[i].ptr[j]; 
    }
  }
  gettimeofday(&end, 0);
  timersub(&end, &start, &diff);
  printf("C: %ld.%06ld\n", (long)diff.tv_sec, (long)diff.tv_usec); 
  printf("%d\n", sum);
  */

  /*
  gettimeofday(&start, 0);
  int32_t *sums = get_global();
  print();
  for (int i = 0; i < LEN; i++) {
    sums[0] += v1.ptr[i]; 
  }
  gettimeofday(&end, 0);
  timersub(&end, &start, &diff);
  printf("C (Mem): %ld.%06ld\n", (long)diff.tv_sec, (long)diff.tv_usec); 
  printf("%d\n", sums[0]);
  */

  // assert(res.size == LEN);
  // int passed = 0;
  /*
  passed += (res.ptr[0] == 0);
  for (int i = 0; i < LEN; i++) {
    passed += (res.ptr[i * 3 + 1] == 1);
    passed += (res.ptr[i * 3 + 2] == 0);
    passed += (res.ptr[i * 3 + 3] == 2);
  }
  passed += (res.ptr[LEN * 3 + 1] == 3);
  assert(passed == LEN * 3 + 2);
  */
  // for (int i = 0; i < LEN; i++) {
  //   passed += (res.ptr[i] == 2*i);
  // }
  // assert(passed == LEN);
  // printf("passed!\n");

  /*
  i32 *out = (i32 *)malloc(LEN * sizeof(i32));
  gettimeofday(&start, 0);
  // vector<i32> v;
  for (int i = 0; i < LEN; i++) {
    // v.push_back(v1.ptr[i] + v2.ptr[i]); 
    out[i] = v1.ptr[i] + v2.ptr[i];
  }
  gettimeofday(&end, 0);
  timersub(&end, &start, &diff);
  printf("C: %ld.%06ld\n", (long)diff.tv_sec, (long)diff.tv_usec);
  printf("%d\n", out[0]);
  */
  return 0;
}
