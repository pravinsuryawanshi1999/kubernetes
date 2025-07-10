#!/bin/bash

ms_name=$@
EX_PASS=1
EX_RETRY=0

if [[ -z $@ ]]; then 
   echo "no ms found,existing"
   exit 1 ;
fi

for ms in $ms_name ; do 
echo " scaling down $ms to zero replicas"
kubectl scale --replicas=0 deployment/$ms
if [[ $? -ne 0 ]]; then 
      echo "failed to set the replicas for servervice $ms";
else
      echo "${ms} replica set to 0"
fi

done

function checkPod()
{
 service_name=$1
 npods=`kubectl get pods  | grep ^${service_name} | awk '{ print $1 }' | wc -l`
 if [[ $npods -lt 1 ]]; then 
       EX_PASS=0;
 
 else
      EX_PASS=1 
      echo "${service_name} still has more than 0 replicas running...."
      echo "sleeping for minute...."
      sleep 60
fi     

}

function loopOverMs()
{
  if [[ $EX_RETRY -gt 3 ]]; then
     echo "Pos still not yet down after 3 retries..., exiting now..."
     exit 1;

  else
     EX_RETRY=$((EX_RETRY+1))
     echo "Running retry: ${EX_RETRY}"
  fi
  for ms in $ms_name ; do 
   echo "checking for $ms"
   checkPod $ms
  done

}


while [[ $EX_PASS -eq 1 ]]; do 
         loopOverMs
done

if [[ $EX_PASS -eq 0 ]]; then
   echo "all pods are down confirmed"
fi
