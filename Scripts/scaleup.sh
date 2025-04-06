#!/bin/bash

ms_name=$@
EX_PASS=1
EX_RETRY=0

if [[ -z $@ ]] ; then 
   echo "no ms found, existing...."
   exit 1;
fi

for ms in $ms_name; do 
    echo "scaling up the microservice to min capacity 1"
    kubectl scale --replicas=1 deployment/${ms} 
    if [[ $? -gt 0 ]] ; then
       echo "failed to set replicas to service ${ms}"
    else
     echo "${ms} is set to min replica 1"
    fi
 done



function checkPod()
{
  service=$1
  npods=`kubectl get pods | grep ^${service} | awk '{ print $1 }'| wc -l`
  if [[ ${npods} -gt 0 ]]; then
      EX_PASS=0
  else
     EX_PASS=1
     echo "${ms} service still not up"
     echo "sleeping for 1 min...."
     sleep 60
  fi
} 

function loopOverMs()
{
  if [[ EX_RETRY -gt 3 ]]; then 
        echo "after 3 attemp ms still not up , existing..."
        exit 1
  else
        EX_RETRY=$((EX_RETRY+1))
        echo "running retry is: ${EX_RETRY}"
  fi  

  for ms in $ms_name ; do
     echo "running for ${ms}" 
     checkPod $ms
  done
} 


while [[ EX_PASS -eq 1 ]] ; do 
     loopOverMs
done

if [[ EX_PASS -eq 0 ]]; then 
     echo "service is up and confirmed"
fi  


