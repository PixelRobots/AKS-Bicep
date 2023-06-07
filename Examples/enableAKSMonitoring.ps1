[CmdletBinding(DefaultParametersetName='None')]
param(
   [string] [Parameter(Mandatory = $true)] $subscriptionID = "<ID HERE>",
   [string] [Parameter(Mandatory = $true)] $location = "West Europe",
   [string] [Parameter(Mandatory = $true)] $customerName = "<customer Name>",
   [string] [Parameter(Mandatory = $true)] $aksClusterName = "<AKS Cluster Name>",
   [string] [Parameter(Mandatory = $true)] $aksClusterResourceGroup = "<AKS resource group>",
   [string] [Parameter(Mandatory = $true)] $aksLAWName = "<LAW Name>",
   [string] [Parameter(Mandatory = $true)] $aksLAWResourceGroup = "<LAW resource group>",
   [validateSet("prod", "dev", "test")][string] [Parameter(Mandatory = $true)] $environmentName = "test",# Acceptable values: "prod", "dev", "test"
   <# Deploy switches #>
   [switch] $deploy
)


$deploymentID = (New-Guid).Guid

<# Set Variables #>
az account set --subscription $subscriptionID --output none
if (!$?) {
    Write-Host "Something went wrong while setting the correct subscription. Please check and try again." -ForegroundColor Red
}

$updatedBy = (az account show | ConvertFrom-Json).user.name 
$location = $location.ToLower() -replace " ", ""
$customerName = $customerName.ToLower() -replace " ", ""

$LocationShortCodeMap = @{
    "westeurope" = "weu";
    "northeurope" = "neu";
    "eastus" = "eus";
    "westus" = "wus";
    "uksouth" = "uks";
    "ukwest" = "ukw"
}

$locationShortCode = $LocationShortCodeMap.$location


# Run section

if ($deploy) {
    <# deployment timer start #>
    $starttime = [System.DateTime]::Now

    Write-Host "Running a Bicep deployment with ID: '$deploymentID' for Customer: $customerName and Environment: '$environmentName' with a 'WhatIf' check." -ForegroundColor Green
        az deployment sub create `
        --name $deploymentID `
        --location $location `
        --template-file ./enable-Prometheus.bicep `
        --parameters updatedBy=$updatedBy customerName=$customerName environmentName=$environmentName location=$location locationshortcode=$LocationShortCode aksClusterName=$aksClusterName aksClusterResourceGroup=$aksClusterResourceGroup aksLAWName=$aksLAWName aksLAWResourceGroup=$aksLAWResourceGroup `
        --confirm-with-what-if `
        --output none

    if (!$?) {
        Write-Host ""
        Write-Host "Bicep deployment with ID: '$deploymentID' for Customer: $customerName and Environment: '$environmentName' Failed" -ForegroundColor Red
    }
    else {
    }

    <# Deployment timer end #>
    $endtime = [System.DateTime]::Now
    $duration = $endtime -$starttime
    Write-Host ('This deployment took : {0:mm} minutes {0:ss} seconds' -f $duration) -BackgroundColor Yellow -ForegroundColor Magenta
}
