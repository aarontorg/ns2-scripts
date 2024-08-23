#! /bin/bash

# Script to update worker-node images
# If you run the script with a landscape name "sap-landscape-preprod" as an argument, it will only do that landscape
# If you want to do multiple, create a landscapes.txt file in the same directory with the name of each landscape on a separate line
# logs will be created for each landscape

export GCTL_SESSION_ID=$(uuidgen)
alias gardenctl=/usr/local/bin/gardenctl
eval $(gardenctl kubectl-env bash)
date=$(date '+%d-%m-%Y')

newUbuntuImage="20.4.20240621"
newSuseImage="15.5.20240307"
landscapes=()

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
	totalProjects=0
	totalProjectsNeedUpdate=0
	totalShoots=0
	totalShootsNeedUpdate=0
	totalWorkers=0
	totalWorkersNeedUpdate=0
  logfile="$landscape-ami-check-$date.log"

	echo "##################################################" > $logfile
	echo "LANDSCAPE: $landscape" >> $logfile
	echo "" >> $logfile
	/usr/local/bin/gardenctl target --garden $landscape

	for ns in $(kubectl get projects -A | grep -v NAME | awk '{print $2}' ) 
	do
		echo "PROJECT: $ns" >> $logfile
		totalProjects=$((totalProjects+1))
    projectShoots=0
    projectShootsNeedUpdate=0

		for shoot in $(kubectl get shoots -n $ns | grep -v NAME | awk '{print $1}')
		do
      projectShoots=$((projectShoots+1))
			# Find workers within shoots
			shootWorkers=0
      shootWorkersNeedUpdate=0
			workerIndex=0
			patchCMD="kubectl replace shoot $shoot -n $ns --type='json'"
			for worker in $(kubectl get shoot $shoot -n $ns -o jsonpath='{.spec.provider.workers[*].name}')
			do
				shootWorkers=$((shootWorkers+1))
				amiName=$(kubectl get shoot $shoot -n $ns -o jsonpath="'{.spec.provider.workers[$workerIndex].machine.image.name}'" | awk -v char="'" '{gsub(char,""); print}')
				amiVersion=$(kubectl get shoot $shoot -n $ns -o jsonpath="'{.spec.provider.workers[$workerIndex].machine.image.version}'" | awk -v char="'" '{gsub(char,""); print}')
        if [ "$amiName" == "ubuntu" ] && [ "$amiVersion" != "$newUbuntuImage" ]; then
          shootWorkersNeedUpdate=$((shootWorkersNeedUpdate+1))
          echo "  SHOOT: $shoot WORKER: $worker AMI_FAMILY: $amiName AMI_VERSION: $amiVersion --> $newUbuntuImage" >> $logfile
					patchCMD+=" -p='[{"op": "patch", "path": /spec/provider/workers/$workerIndex/machine/image/version, "value": "$newUbuntuImage"}]'"
				elif [ "$amiName" == "suse-chost" ] && [ "$amiVersion" != "$newSuseImage" ]; then
				  shootWorkersNeedUpdate=$((shootWorkersNeedUpdate+1))
          echo "  SHOOT: $shoot WORKER: $worker AMI_FAMILY: $amiName AMI_VERSION: $amiVersion --> $newSuseImage" >> $logfile
          patchCMD+=" -p='[{"op": "patch", "path": /spec/provider/workers/$workerIndex/machine/image/version, "value": "$newSuseImage"}]'"
        fi
				workerIndex=$((workerIndex+1))  
			done
			totalWorkers=$((totalWorkers+$shootWorkers))
			if [[ $shootWorkersNeedUpdate > 0 ]]; then
				echo "   If you want to update this shoot and all workers, run this command:" >> $logfile
				echo "   # $patchCMD" >> $logfile
				totalWorkersNeedUpdate=$((totalWorkersNeedUpdate + $shootWorkersNeedUpdate))
        projectShootsNeedUpdate=$((projectShootsNeedUpdate+1))
			fi
		done

		echo "---------------------------------------------------" >> $logfile
		echo "" >> $logfile
    totalShoots=$((totalShoots+$projectShoots))
    totalShootsNeedUpdate=$((totalShootsNeedUpdate+$projectShootsNeedUpdate))
		if [[ $projectShootsNeedUpdate > 0 ]]; then
			totalProjectsNeedUpdate=$((totalProjectsNeedUpdate+1))
    fi
	done

	echo "LANDSCAPE: $landscape" >> $logfile
	echo " PROJECTS: $totalProjects" >> $logfile
	echo " PROJECTS NEED UPDATE: $totalProjectsNeedUpdate" >> $logfile
	echo " SHOOTS: $totalShoots" >> $logfile
	echo " SHOOTS NEED UPDATE: $totalShootsNeedUpdate" >> $logfile
	echo " WORKERS: $totalWorkers" >> $logfile
	echo " WORKERS NEED UPDATE: $totalWorkersNeedUpdate" >> $logfile
	echo "##################################################" >> $logfile
done
