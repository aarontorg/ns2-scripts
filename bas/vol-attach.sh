#! /bin/bash

for x in $(kubectl get volumeattachments | grep -v NAME | awk '{print $4}')
do
  check=$(kubectl get node $x | grep -v NAME | awk '{print $1}')
  if [[ "$x" == "$check" ]]; then
    echo "$x - GOOD"
  else
    echo "$x - BAD"
  fi
done
