#! /bin/bash

date=$(date '+%d-%m-%Y')
boundary=$1
project=$2
shoot=$3
logfile="logs/sap-landscape-$boundary-running-container-report-$date.csv"

while read -r LINE
	do
	  echo "$project,$shoot,$LINE" >> $logfile
done < ./hxm/sap-landscape-$boundary-$project-$shoot.log