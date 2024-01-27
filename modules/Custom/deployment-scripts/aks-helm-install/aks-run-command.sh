#!/bin/bash

set -e +H
# -e to exit on error
# +H to prevent history expansion

# Set the script's locale to UTF-8 to ensure proper handling of UTF-8 encoded text
export LANG=C.UTF-8

if [ "$initialDelay" != "0" ]
then
    echo "Waiting on RBAC replication ($initialDelay)"
    sleep $initialDelay

    #Force RBAC refresh
    az logout
    az login --identity
fi

# Define the filename for the Helm values
helmValuesFileName="$(dirname "$0")/helmvalues.yaml"

echo "Creating Helm values file..."
echo -n $helmAppValues | base64 -d > $helmValuesFileName
echo "Helm values file created and stored at $helmValuesFileName"

echo "Sending command to AKS Cluster $aksName in $RG"
cmdOut=$(az aks command invoke -g $RG -n $aksName  --command "helm repo add ${helmRepo} ${helmRepoURL} && helm repo update && helm upgrade --install ${helmAppName} ${helmApp} ${helmAppParams} -f $helmValuesFileName" --file $helmValuesFileName -o json)
echo $cmdOut

jsonOutputString=$cmdOut
echo $jsonOutputString > $AZ_SCRIPTS_OUTPUT_PATH
