#! /bin/sh
# Update the solacecert

ns=$1

#for ns in $(kubectl get solacesoftwarebroker -A | grep -v NAME | grep failed | awk {'print $1'}) 
#do
  echo "NS: $ns"
  for ssb in $(kubectl get solacesoftwarebroker -n $ns | grep -v NAME | grep -v "ready" | awk {'print $1'})
  do
    echo "SSB: $ssb"
    # Copy cert
    for (( i=0 ; ((i-3)) ; i=(($i+1)) ))
    do
      echo "Copying files to $ns ${ssb}-${i}"
      echo "kubectl cp ./servercert.pem ${ns}/ssb-${ssb}-${i}:/usr/sw/jail/certs -c solace"
      kubectl cp ./servercert.pem ${ns}/ssb-${ssb}-${i}:/usr/sw/jail/certs -c solace
      kubectl exec -it ssb-${ssb}-${i} --container solace -n ${ns} -- /bin/bash
    done
  done
  # Update the statusRevision
  #statusRevisionCount=$(kubectl get solacesoftwarebroker ${ssb} -n ${ns} -o jsonpath='{.spec.statusRevisionCount}')
  #echo "Old statusRevisionCount = ${statusRevisionCount}"
  #statusRevisionCount=$((statusRevisionCount+1))
  #echo "New statusRevisionCount = ${statusRevisionCount}"
  kubectl edit solacesoftwarebroker ${ssb} -n ${ns}
#done

echo "Done"
