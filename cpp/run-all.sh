#!/bin/bash
for n in 4194304 16777216 67108864; do
  for prog in run; do
    RUNS=""
    for i in 1 2 3; do
      TIME=$(timeout 400 ./$prog 268435456 16 $n 0)
      if [ -z $TIME ]; then
        TIME=400.0
      fi
      RUNS="$TIME,$RUNS"
    done
    echo $RUNS
    echo $prog,$n,$(python -c "print sum([$RUNS])/3.0")
  done
done
