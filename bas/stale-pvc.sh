#! /bin/bash

# Get workspaces then check pvcs, nodes and volumeattachments
# Check for:
# 1. volumeattachments on an existing node
# 2. pvc and volumeattachment are using same pv
# 3. annotation on the pvc matches the node (this may not always be true ... not sure when this would get updated)

# Get a list of workspaces or use $1 for a specific one
if [[ $1 != "" ]]; then
  workspaces=$(kubectl get workspace $1 -n workspaces -o json)
else
  workspaces=$(kubectl get workspaces -n workspaces -o json | jq '.items[]')
fi
#nodes=$(kubectl get nodes -o json | jq '.items[]')
pvcs=$(kubectl get pvc -A -o json | jq '.items[]')
volumeattachments=$(kubectl get volumeattachments -o json | jq '.items[]')

for ws in $(jq -r '.metadata.name' <<< ${workspaces})
do
  export workspace=$ws
  ns=$(jq -r '. | select(.metadata.name | match($ENV.workspace)) | .status.namespace' <<< $workspaces)
  suspended=$(jq -r '. | select(.metadata.name | match($ENV.workspace)) | .status.suspended' <<< ${workspaces})
  user=$(jq  -r '. | select(.metadata.name | match($ENV.workspace)) | .spec.username' <<< ${workspaces})
  echo "Workspace: $ws User: $user Namespace: $ns Suspended: $suspended"
  for pvc in $(jq -r '. | select(.metadata.name | match($ENV.workspace)) | .metadata.name' <<< ${pvcs})
  do
    export pv=$(jq -r '. | select(.metadata.name | match($ENV.workspace)) | .spec.volumeName' <<< $pvcs)
    export pvcNode=$(jq -r '. | select(.metadata.name | match($ENV.workspace)) | .metadata | .annotations | ."volume.kubernetes.io/selected-node"' <<< $pvcs)
    export volAttachedNode=$(jq -r '. | select(.spec.source.persistentVolumeName | match($ENV.pv)) | .spec.nodeName' <<< $volumeattachments)
    volAttached=$(jq -r '. | select(.spec.source.persistentVolumeName | match($ENV.pv)) | .status.attached' <<< $volumeattachments)
    volAttachedName=$(jq -r '. | select(.spec.source.persistentVolumeName | match($ENV.pv)) | .metadata.name' <<< $volumeattachments)
    #echo "  PVC: $pvc PV: $pv PvcNode: $pvcNode"
    #echo "  VolAttachedName: $volAttachedName VolAttachNode: $volAttachedNode VolAttached: $volAttached"
    pod=$(kubectl get pods -n $ns | grep -v NAME | awk '{print "Pod:", $1, "Status:", $3}')
    podStatus=$(echo $pod | awk '{print $4}')
    echo "  $pod"
    if [[ "$podStatus" == "Terminating" ]]; then
      echo "    # kubectl delete volumeattachments.storage $volAttachedName"
    fi

    # Not really needed at this time ...
    #if [[ "$volAttached" != "" ]]; then
    #  if [[ "$pvcNode" != "$volAttachedNode" ]]; then
    #    echo "     - PVC Node annotation does not match volumeattachment node"
    #  fi
    #  # Check if volumeattachmentnode is a real node
    #  echo "    Checking if VolumeAttachment node exists"
    #  nodeMatch=$(jq -r '. | select(.metadata.name | match($ENV.volAttachedNode)) | .metadata.name' <<< $nodes)
    #  if [[ "$volAttachedNode" == "$nodeMatch" ]]; then
    #    echo "     MATCH: $volAttachedNode -- $nodeMatch"
    #  else
    #    echo "     NO_MATCH: $volAttachedNode -- $nodeMatch"
    #  fi
    #else
    #  echo "     No Volume attachment found"
    #fi
  done
done

