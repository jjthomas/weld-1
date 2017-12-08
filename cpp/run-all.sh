#!/bin/bash
for n in 1 4 16 64 256 1024 4096 16384 65536 262144 1048576 4194304 16777216 67108864 268435456; do
  for prog in run run-local run-global; do
    RUNS=""
    for i in 1; do
      TIME=$(timeout 3600 ./$prog 2147483648 16 $n 0)
      if [ -z $TIME ]; then
        TIME=3600.0
      fi
      RUNS="$TIME,$RUNS"
    done
    echo $RUNS
    echo $prog,$n,$(python -c "print sum([$RUNS])/1.0")
  done
done
