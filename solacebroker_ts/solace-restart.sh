#! /bin/sh
# Update the solacecert

for ns in $(kubectl get solacesoftwarebroker -A | grep -v NAME | grep -v ready | awk {'print $1'}) 
do
  echo "NS is $ns"
  for ssb in $(kubectl get solacesoftwarebroker -n $ns | grep -v NAME  | awk {'print $1'})
  do
  	# Update the statusRevision
  	statusRevisionCount=$(kubectl get solacesoftwarebroker ${ssb} -n ${ns} -o jsonpath='{.spec.statusRevisionCount}')
  	echo "Old statusRevisionCount = ${statusRevisionCount}"
  	statusRevisionCount=$((statusRevisionCount+1))
  	echo "New statusRevisionCount = ${statusRevisionCount}"
  	kubectl patch solacesoftwarebroker ${ssb} -n ${ns} -p '{"spec":{"statusRevisionCount":${statusRevisionCount}}}'
  done
  echo "Exiting doing one at a time"
  exit 0
done

echo "Done"
