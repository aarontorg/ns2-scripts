#! /bin/bash

# kubectl get pod workspaces-ws-xl578-deployment-66ddd48f89-xvdg8 -n ws-ns-workspaces-ws-xl578 -o jsonpath='{.spec.containers[*].resources}'

i=0
for container in $(kubectl get pod workspaces-ws-xl578-deployment-66ddd48f89-xvdg8 -n ws-ns-workspaces-ws-xl578 -o jsonpath='{.spec.containers[*].name}') 
do
	echo "Container: $container"
        echo " Requests: "
	memReq=$(kubectl get pod workspaces-ws-xl578-deployment-66ddd48f89-xvdg8 -n ws-ns-workspaces-ws-xl578 -o jsonpath="{.spec.containers[$i].resources.requests.memory}")
	echo "  Memory: $memReq"
	cpuReq=$(kubectl get pod workspaces-ws-xl578-deployment-66ddd48f89-xvdg8 -n ws-ns-workspaces-ws-xl578 -o jsonpath="{.spec.containers[$i].resources.requests.cpu}")
        echo "  CPU: $cpuReq"
	memLimit=$(kubectl get pod workspaces-ws-xl578-deployment-66ddd48f89-xvdg8 -n ws-ns-workspaces-ws-xl578 -o jsonpath="{.spec.containers[$i].resources.limits.memory}")
        echo " Limits: "
	echo "  Memory: $memLimit"
	cpuLimit=$(kubectl get pod workspaces-ws-xl578-deployment-66ddd48f89-xvdg8 -n ws-ns-workspaces-ws-xl578 -o jsonpath="{.spec.containers[$i].resources.limits.cpu}")
        echo "  CPU: $cpuLimit"
	i=$((i+1))
done
