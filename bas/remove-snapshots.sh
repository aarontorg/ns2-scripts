#! /bin/bash

# Script to cleanup bas terminating namespaces
# --dry-run is setup for the 

dryRun=client #Leave at client to test the script to see what it will do. Change to none when ready to run

# Get list of terminating namespaces
for ns in $(kubectl get ns | grep Terminating | awk '{print $1}')
do
  msg="No resources found in $ns namespace."
  ## Find referencing volumesnapshots
  echo "Looking for volumesnapshots in namespace ... $ns"
  for vss in $(kubectl get volumesnapshot -n $ns | awk '{print $1}' | grep -v NAME) 
  do
    if [ "$vss" != "$msg" ]; then 
  	  echo "Patching volumesnapshot $vss in namespace $ns to remove finalizer"
#      kubectl patch volumesnapshot/$vss -n $ns --type json --patch='[{"op": "remove", "path": "/metadata/finalizers"}]' --dry-run=${dryRun}
    fi
  done

  ## Also need to look for volumesnapshot contents
  echo "Looking for volumesnapshotcontents in namespace ... $ns"
  for vssc in $(kubectl get volumesnapshotcontents -n $ns | awk '{print $1}' | grep -v NAME)
  do    
    if [ "$vssc" != "$msg" ]; then
      echo "Patching volumesnapshotcontents $vssc in namespace $ns to remove finalizer"
#      kubectl patch volumesnapshotcontents/$vssc -n $ns --type json --patch='[{"op": "remove", "path": "/metadata/finalizers"}]' --dry-run=${dryRun}
    fi
  done
done
