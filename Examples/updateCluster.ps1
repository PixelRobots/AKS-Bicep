[CmdletBinding(DefaultParametersetName='None')]
param(
   [string] [Parameter(Mandatory = $true)] $subscriptionID = "<ID HERE>",
   [string] [Parameter(Mandatory = $true)] $location = "West Europe",
   [string] [Parameter(Mandatory = $true)] $aksClusterName = "<AKS Cluster Name>",
   [string] [Parameter(Mandatory = $true)] $aksClusterResourceGroup = "<AKS resource group>",
   <# Deploy switches #>
   [switch] $update
)


$deploymentID = (New-Guid).Guid

<# Set Variables #>
az account set --subscription $subscriptionID --output none
if (!$?) {
    Write-Host "Something went wrong while setting the correct subscription. Please check and try again." -ForegroundColor Red
}

# Run section

if ($update) {
    <# deployment timer start #>
    $starttime = [System.DateTime]::Now

    Write-Host "Running a Bicep deployment with ID: '$deploymentID' for Cluster: $aksClusterName with a 'WhatIf' check." -ForegroundColor Green
        az deployment sub create `
        --name $deploymentID `
        --location $location `
        --template-file ./update-cluster.bicep `
        --parameters location=$location aksClusterName=$aksClusterName aksClusterResourceGroup=$aksClusterResourceGroup `
        --confirm-with-what-if `
        --output none

    if (!$?) {
        Write-Host ""
        Write-Host "Bicep deployment with ID: '$deploymentID' for Cluster: $aksClusterName Failed" -ForegroundColor Red
    }
    else {
    }

    <# Deployment timer end #>
    $endtime = [System.DateTime]::Now
    $duration = $endtime -$starttime
    Write-Host ('This deployment took : {0:mm} minutes {0:ss} seconds' -f $duration) -BackgroundColor Yellow -ForegroundColor Magenta
}
