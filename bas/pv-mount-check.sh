#! /bin/bash

#kubectl get pvc workspaces-ws-wz6q6-data -n ws-ns-workspaces-ws-wz6q6 -o jsonpath='{.metadata.annotations.volume\.kubernetes\.io/selected-node}'

# Build array of node ips

nodes=()
for n in $(kubectl get nodes -l worker.gardener.cloud/pool=ws | awk {'print $1'} | grep -v NAME)
do
  nodes+=($n)
done

matches=0
nomatches=0
# Get a list of workspace namespaces
for ns in $(kubectl get ns | grep ws-ns-workspaces | awk {'print $1'})
do
  echo "NS: $ns"
	# Get pvcs in the namespace
	for pvc in $(kubectl get pvc -n $ns | grep -v NAME | awk {'print $1'})
	do
	  echo "  PVC: $pvc"
	  # Get the node annotation
	  pvNode=$(kubectl get pvc $pvc -n $ns -o jsonpath='{.metadata.annotations.volume\.kubernetes\.io/selected-node}')
	  # Check if pvNode matches any nodes in a list
	  match=false
	  for n in ${nodes[@]};
	  do
	    if [[ $pvNode == $n ]]; then
	      match=true
	      matches=$((matches+1))
	      echo "    MATCH: $ns PVC: $pvc PVCNODE: $pvNode NODE: $n"
	    fi
	  done
	  if [[ $match != true ]]; then
	    echo "    NO-MATCH: $ns PVC: $pvc PVCNODE: $pvNode"
	    nomatches=$((nomatches+1))
	  fi
	done
done

echo "MATCHES: $matches"
echo "NOMATCHES: $nomatches"
