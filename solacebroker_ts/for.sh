#!/bin/bash

ns="vmr-136354ad-caf8-4103-a009-c56e16da4529"
ssb="136354ad-caf8-4103-a009-c56e16da4529"

for (( i=0 ; ((i-3)) ; i=(($i+1)) ))
do 
  echo $i 
  kubectl exec -it ssb-${ssb}-${i} --container solace -n ${ns} -- /bin/bash <<EOF
  #cli 
  #enable
  #configure
  #exit
  #exit
  EOF
done
