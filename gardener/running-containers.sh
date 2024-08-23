#! /bin/bash

# Script to generate running container report for each project
export GCTL_SESSION_ID=$(uuidgen)
alias gardenctl=/usr/local/bin/gardenctl
eval $(gardenctl kubectl-env bash)
date=$(date '+%d-%m-%Y')
landscapes=()
mkdir logs

# Check if landscape given as argument, otherwise run report for all of landscapes
if [[ $1 != "" ]]; then
        landscapes+=$1
else
        while read -r LINE
        do
          landscapes+=("$LINE")
        done < ./landscapes.txt
fi

for landscape in "${landscapes[@]}"
do
  logfile="logs/$landscape-running-container-report-$date.csv"
  echo "Project,Shoot-Cluster,Date,ENV1,ENV2,Num,SHA,Image" > $logfile
  /usr/local/bin/gardenctl target --garden $landscape

  for project in $(kubectl get projects -A -o json | jq -r '.items[].metadata.name')
  do
    echo "PROJECT: $project"
		namespace="garden"
		if [ "$project" != "garden" ]; then
		  namespace+="-$project"
		fi
		# Get all the shoots
		for shoot in $(kubectl get shoots -n $namespace -o json | jq -r '.items[].metadata.name')
		do
		  echo "  SHOOT: $shoot"
      /usr/local/bin/gardenctl target --garden $landscape --project $project --shoot $shoot
      check=$(kubectl get ns managed-resources -o json | jq -r '.status.phase')
      if [ "$check" == "Active" ]; then
        pod=$(kubectl get pods -n managed-resources --sort-by=.metadata.creationTimestamp -o json | jq -r '[.items[].metadata | select(.name | match("running-container-report-.*"))] | .[-1].name')
        echo "     POD: $pod"
        for line in $(kubectl logs $pod -n managed-resources)
        do
          echo "$project,$shoot,$line" >> $logfile
        done
      else
        echo "$project,$shoot,'Unable to connect',,,,," >> $logfile
      fi
		done
		/usr/local/bin/gardenctl target --garden $landscape
	done
done