[CmdletBinding(DefaultParametersetName = 'None')]
param(
    [string][Parameter(Mandatory = $true)] $subscriptionID,
    [string][Parameter(Mandatory = $true)] $location = "uksouth",
    [string][Parameter(Mandatory = $true)] $azureMonitorWorkspaceName,
    [string][Parameter(Mandatory = $true)] $azureMonitorWorkspaceResourceGroup,
    [string][Parameter(Mandatory = $true)] $grafanaWorkspaceName,
    [string][Parameter(Mandatory = $true)] $grafanaWorkspaceResourceGroup,
    [switch]$deploy
)

$templateParameters = @{ # Define your template parameters here as needed
    azureMonitorWorkspaceName          = $azureMonitorWorkspaceName
    azureMonitorWorkspaceResourceGroup = $azureMonitorWorkspaceResourceGroup
    grafanaWorkspaceName               = $grafanaWorkspaceName
    grafanaWorkspaceResourceGroup      = $grafanaWorkspaceResourceGroup
}

function Set-AzContext {
    param (
        [string]$subscriptionId
    )
    az account set --subscription $subscriptionId --output none
    if (!$?) {
        Write-Error "Failed to set Azure subscription context to $subscriptionId."
        exit 1
    }
    else {
        Write-Host "Azure subscription context set to $subscriptionId." -ForegroundColor Green
    }
}

function Deploy-BicepFile {
    param (
        [string]$deploymentName,
        [string]$location,
        $templateParameters = @{}
    )
    $params = ($templateParameters.GetEnumerator() | ForEach-Object { "--parameters $($_.Key)='$($_.Value)'" }) -join " "
    $cmd = "az deployment sub create --name $deploymentName --template-file .\update-Grafana-integrations.bicep $params --location $location --confirm-with-what-if --output none"
    
    try {
        Invoke-Expression $cmd
        Write-Host "Deployment '$deploymentName' completed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error "Deployment '$deploymentName' failed with error: $_"
        exit 1
    }
}

# Main script execution
Set-AzContext -subscriptionId $subscriptionID

if ($deploy) {
    $startTime = [DateTime]::Now
    $deploymentName = (New-Guid).Guid
    Write-Host "Initiating Bicep deployment: $deploymentName" -ForegroundColor Green
    
    Deploy-BicepFile -deploymentName $deploymentName -location $location -resourceGroupName $resourceGroupName -bicepFilePath .\update-Grafana-integrations.bicep -templateParameters $templateParameters
    
    $endTime = [DateTime]::Now
    $duration = $endTime - $startTime
    Write-Host "Deployment duration: $($duration.Minutes) minutes $($duration.Seconds) seconds" -ForegroundColor Yellow
}
else {
    Write-Host "Update switch not set. Deployment skipped." -ForegroundColor Yellow
}
