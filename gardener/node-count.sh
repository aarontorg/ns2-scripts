#! /bin/bash

# Script to count number of nodes in a project
export GCTL_SESSION_ID=$(uuidgen)
alias gardenctl=/usr/local/bin/gardenctl
eval $(gardenctl kubectl-env bash)
landscapes=()

# Check if landscape given as argument, otherwise run report for all of landscapes
if [[ $1 != "" ]]; then
        landscapes+=$1
else
        while read -r LINE
        do
          landscapes+=("$LINE")
        done < ./landscapes.txt
fi

nodeCount=0
for landscape in "${landscapes[@]}"
do
  /usr/local/bin/gardenctl target --garden $landscape
  for project in $(kubectl get projects -A -o json | jq -r '.items[].metadata.name')
  do
		namespace="garden"
		if [ "$project" != "garden" ]; then
		  namespace+="-$project"
		fi
		# Get all the shoots
		for shoot in $(kubectl get shoots -n $namespace -o json | jq -r '.items[].metadata.name')
		do
      /usr/local/bin/gardenctl target --garden $landscape --project $project --shoot $shoot
      shootNodes=$(kubectl get nodes | grep -v NAME | wc -l)
      echo "    ShootNodes: $shootNodes"
      nodeCount=$((nodeCount+$shootNodes))
    done
    /usr/local/bin/gardenctl target --garden $landscape
	done
done
echo "Total Nodes: $nodeCount"
