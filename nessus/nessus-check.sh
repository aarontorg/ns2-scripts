#! /bin/zsh

export GCTL_SESSION_ID=$(uuidgen)
alias gardenctl=/usr/local/bin/gardenctl
eval $(gardenctl kubectl-env bash)

while read -r LINE
do
        date=$(date '+%Y-%m-%d')
	type=$(echo $LINE | awk '{print $1}')
	garden=$(echo $LINE | awk '{print $2}')
	seedOrProject=$(echo $LINE | awk '{print $3}')
        logfile="$garden-$seedOrProject-$date.log"
	
	if [[ "$type" == "seed" ]] && [[ "$1" != "shoot" ]]; then
		echo "## GARDEN: $garden SEED: $seedOrProject ##" >> $logfile
		echo "---------------------" >> $logfile
		/usr/local/bin/gardenctl target --garden $garden seed $seedOrProject
        elif [[ "$type" == "shoot" ]] && [[ "$1" != "seed" ]]; then
                shoot=$(echo $LINE | awk '{print $4}')
		echo "## GARDEN: $garden PROJECT: $seedOrProject SHOOT: $shoot ##" >> $logfile
		echo "---------------------" >> $logfile
		/usr/local/bin/gardenctl target --garden $garden --project $seedOrProject  --shoot $shoot
        fi 

	for pod in $(kubectl get pods -n kube-system | awk '{print $1}' | grep -v NAME | grep nessusagent-) 
	do
                ip=$(kubectl exec $pod -n kube-system -- curl ifconfig.me)
        	echo "POD: $pod IP: $ip" >> $logfile
		kubectl exec $pod -n kube-system -- /opt/nessus_agent/sbin/nessuscli agent status >> $logfile
		echo "" >> $logfile
	done
	echo "--------------------" >> $logfile
done < ./nessus-checks.txt


