#!/bin/bash

deploy_ms(){
    [[ -z $1 ]] && echo "provide microservice name" && return 1
    MS_NAME=$1

    HELM_PARAMS="upgrade -i --force ${MS_NAME} /Users/pravisur/Pravin/local/helm-charts/${MS_NAME} --set name=$MS_NAME --set image.repository=localhost:8082/$MS_NAME"

    if [[ $FORCE_RECREATE_PODS -eq 1 ]]; then
        HELM_PARAMS=" ${HELM_PARAMS} --recreate-pods "
    fi

    echo "Starting deployment of $MS_NAME with Helm: ${HELM_PARAMS}"
    helm ${HELM_PARAMS}

    if [[ $? -ne 0 ]]; then
        echo "ERROR - failed while deploying"
        exit 1
    fi
}

if [[ $# -lt 2 ]]; then
    echo "No of arguments provided to the script is less than required. Please check"
    exit 1
fi 

export FORCE_RECREATE_PODS=$1

CUSTOM_MS_LIST="custom-ms-list.txt"

echo "***CUSTOM_MS_LIST: ${CUSTOM_MS_LIST}***"

if [[ "$2" != 'ALL' ]]; then
    MS_NAME=$2
    echo "Deploying single microservice: $MS_NAME"
    deploy_ms $MS_NAME
else
    echo "Deploying all microservices listed in $CUSTOM_MS_LIST"
    for MS_NAME in $(cat $CUSTOM_MS_LIST); do
        echo "Deploying $MS_NAME"
        deploy_ms $MS_NAME
    done
fi

