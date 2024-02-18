# Enable Prometheus on an existing AKS cluster

`enableAKSMonitoring.ps1` is a Bicep deployment script written in PowerShell. It deploys Azure resources based on the specified parameters.

## Parameters

- `subscriptionID`: The ID of the Azure subscription to deploy the resources.
- `location`: The location where the resources will be deployed.
- `customerName`: The name of the customer.
- `aksClusterName`: The name of the AKS (Azure Kubernetes Service) cluster.
- `aksClusterResourceGroup`: The resource group of the AKS cluster.
- `aksLAWName`: The name of the Log Analytics Workspace (LAW).
- `aksLAWResourceGroup`: The resource group of the Log Analytics Workspace.
- `environmentName`: The name of the environment (acceptable values: "prod", "dev", "test").
- `deploy`: A switch parameter to indicate whether to perform the deployment.


## Variables

- `$deploymentID`: A unique identifier for the deployment.
- `$updatedBy`: The username of the Azure account used for deployment.
- `$location`: The lowercase version of the specified location.
- `$customerName`: The lowercase version of the specified customer name.
- `$LocationShortCodeMap`: A hashtable mapping Azure locations to their corresponding short codes.
- `$locationShortCode`: The short code of the specified location.

## Run Section

- `CheckPermissions`: A function to check the permissions of the Azure account.
- If the `deploy` switch parameter is specified, the deployment process starts.

### Deployment Process

- The deployment ID is generated using `New-Guid`.
- The correct Azure subscription is set using `az account set`.
- The `$updatedBy`, `$location`, and `$customerName` variables are updated.
- The location short code is retrieved from the `$LocationShortCodeMap` hashtable.
- The `az deployment sub create` command is executed with the specified parameters and a "WhatIf" check.
- If the deployment is successful, a success message is displayed. Otherwise, a failure message is displayed.
- The duration of the deployment is calculated and displayed.

## Usage

You can run this script by providing the required parameters. Make sure to have the necessary PowerShell scripts in the specified path.

Example:

```powershell
.\deploy-bicep.ps1 
  -subscriptionID <string>
  -location <string>
  -customerName <string>
  -aksClusterName <string>
  -aksClusterResourceGroup <string>
  -aksLAWName <string>
  -aksLAWResourceGroup <string>
  -environmentName [dev, test, prod]
  -deploy
```

You can use the below as a one liner to copy into your terminal window.

```powershell
.\deploy-bicep.ps1 -subscriptionID "<ID HERE>" -location "West Europe" -customerName "<customer Name>" -aksClusterName "<AKS Cluster Name>" -aksClusterResourceGroup "<AKS resource group>" -aksLAWName "<LAW Name>" -aksLAWResourceGroup "<LAW resource group>" -environmentName "test" -deploy
```

Lets take a look at what is in the bicep.

<hr>
<br>

# Bicep File - enable-Prometheus.bicep

This file operates at subscription level. It is a modular deployment that calls Bicep modules within the `/modules` directory. The only resources directly deployed by this file are the resource groups.

This file can only be deployed at a subscription scope.

## Parameters and Variables

- `updatedBy` (string): Logged in user details passed from the parent script "deployNow.ps1". Default value: `''`.
- `environmentName` (string): Environment type (e.g., Test, Acceptance/UAT, Production) passed from the parent script "deployNow.ps1". Allowed values: `test`, `dev`, `prod`. Default value: `'test'`.
- `customerName` (string): The customer name.
- `location` (string): Azure Region to deploy the resources in. Allowed values: `westeurope`, `uksouth`. Default value: `'uksouth'`.
- `locationshortcode` (string): Location shortcode used for the end of resource names.
- `tags` (object): Resource tags. Default value:
  ```json
  {
    "Environment": "<environmentName>",
    "Customer": "<customerName>",
    "LastUpdatedOn": "<current date in UTC>",
    "LastDeployedBy": "<updatedBy>"
  }

### Resource Group Parameters

- `resourceGroupArray` (array): Array of resource groups. Each element should contain the following properties:
  - `name` (string): The name of the resource group.
  - `location` (string): The location of the resource group.

### Monitoring Parameters

- `aksLAWName` (string): The name of the Log Analytics used for AKS.
- `aksLAWResourceGroup` (string): The name of the resource group that has the Log Analytics workspace connected to AKS.
- `enableGrafana` (bool): If enabled, deploy Grafana. Default value: `true`.
- `monitorWorspacename` (string): The name of the Azure Monitor workspace.
- `azureMonitorWorkspaceLocation` (string): The location of the Azure Monitor workspace. Allowed values: `eastus2euap`, `centraluseuap`, `centralus`, `eastus`, `eastus2`, `northeurope`, `southcentralus`, `southeastasia`, `uksouth`, `westeurope`, `westus`, `westus2`. Default value: `'westeurope'`.
- `grafanaWorkspaceName` (string): The resource name for Grafana. Minimum length: `2`, Maximum length: `23`.
- `grafanaSKU` (string): The SKU for Grafana. Allowed values: `Standard`. Default value: `'Standard'`.
- `webhookURI` (string): The URI used for the action group to send Prometheus Alerts.

### Azure Kubernetes Service Parameters

- `aksClusterName` (string): The name of the AKS cluster.
- `aksClusterResourceGroup` (string): The name of the resource group that has the AKS cluster.

## Deployment Modules

### Get Existing Resource Values

These resources are used within the Bicep template to reference existing resources and establish relationships with other resources or modules.

```bicep
resource LAWResourceID 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(aksLAWResourceGroup)
  name: aksLAWName
}

resource AKSClusterResourceID 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' existing = {
  scope: resourceGroup(aksClusterResourceGroup)
  name: aksClusterName
}
```

### Deploy Resource Groups

This will either create a new resource group for the monitoring resources to reside in or use an existing one it finds. It will Also **replace the tags on an existing Resource Group**.
```bicep
module

 resourceGroups '../modules/Resources/resourceGroups/main.bicep' = [for (resourceGroup, i) in resourceGroupArray: {
  name: 'rg-${i}-${customerName}-${environmentName}-${locationshortcode}'
  params: {
    name: resourceGroup.name
    location: resourceGroup.location
    tags: tags
  }
}]
```

### Deploy Azure Monitor Workspace

This module will deploy an Azure Monitor Workspace in the monitoring resource group. This resource group is defined under scope.
```bicep
module monitorWorkspace '../modules/Custom/MonitorWorkspace/monitorWorkspace.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: monitorWorspacename
  params: {
    name: monitorWorspacename
    location: azureMonitorWorkspaceLocation
    tags: tags
  }
  
  dependsOn: [
    resourceGroups
  ]
}
```

### Deploy Azure Managed Grafana

This module will deploy Managed Grafana in the monitoring resource group if the `enableGrafana` switch is set to true (it is by default). This resource group is defined under scope.
```bicep
module ManagedGrafana '../modules/Custom/ManagedGrafana/main.bicep' = if (enableGrafana) {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'ManagedGrafana'
  params: {
    location: location
    name: grafanaWorkspaceName
    SKU: grafanaSKU
    azureMonitorWorkspaceResourceId: monitorWorkspace.outputs.resourceId
    identityType: 'SystemAssigned'
    apiKey: 'Disabled'
    deterministicOutboundIP: 'Enabled'
    zoneRedundancy: 'Disabled'
    publicNetworkAccess: 'Enabled'
    tags: tags
  }

  dependsOn: resourceGroups
}
```

### Provide Grafana Access to AMW Instance

This module will assign the Grafana managed identity the `Monitoring Data Reader` role to the monitoring resource group. This is needed to allow Grafana to be able to access the Monitor metrics from the Azure Monitor Workspace. It has to be defined at the resource group level currently as the API's do not support the role at the Azure Monitor Workspace. The resource group is defined under scope.
```bicep
module roleAssignmentGrafanaAMW '../modules/Authorization/roleAssignments/resourceGroup/main.bicep' = if (enableGrafana) {
  name: 'Assign-Grafana-Monitoring-Data-Reader'
  scope: resourceGroup(resourceGroupArray[0].name)
  params: {
    principalId: ManagedGrafana.outputs.principalId
    roleDefinitionIdOrName: 'Monitoring Data Reader'
  }
}
```

### Set up Azure Managed Prometheus

This module will update an existing AKS cluster to enable Managed Prometheus. It will also deploy some Data collection rules and endpoints in teh monitoring resource group. It will also create all recording rules needed. The monitoring resource group is defined under scope.
```bicep
module ManagedPrometheus '../modules/Custom/ManagedPrometheus/main.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'ManagedPrometheus'
  params: {
    updateAKSCluster: true
    azureMonitorWorkspaceLocation: location
    azureMonitorWorkspaceResourceId: monitorWorkspace.outputs.resourceId
    clusterLocation: location
    clusterResourceId: AKSClusterResourceID.id
    enableWindowsRecordingRules: true
    logAnalyticsWorkSpaceId: LAWResourceID.id
    location: location
    tags: tags
  }
}
```

### Deploy Managed Prometheus Alerts Action Group

This module will deploy an Action group with a webhook endpoint. (this endpoint should be changed) in the monitoring resource group. This action group is needed when you configure Prometheus Alerts. This resource group is defined under scope.
```bicep
module ManagedPrometheusAlertsActionGroup '../modules/Insights/actionGroups/main.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'ManagedPrometheusAlertsActionGroup'
  params: {
    name: 'actgrp-${customerName}-${environmentName}-${locationshortcode}'
    groupShortName: 'aks-alerts'
    location: 'global'
    tags: tags
    webhookReceivers: [
      {
        name: 'PrometheusMonitoring'
        serviceURI: webhookURI
        useCommonAlertSchema: true
      }
    ]
  }
}
```

### Deploy Managed Prometheus Alerts

This module will deploy all the community and Azure Prometheus metric alerts to the Azure Monitor Workspace. The resource group is defined under scope.
```bicep
module ManagedPrometheusAlerts '../modules/Custom/ManagedPrometheus/.bicep/nested_prometheus_alerts.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)


  name: 'ManagedPrometheusAlerts'
  params: {
    AKSClusterName: aksClusterName
    actionGroupResourceId: ManagedPrometheusAlertsActionGroup.outputs.resourceId
    azureMonitorWorkspaceResourceId: monitorWorkspace.outputs.resourceId
    location: location
  }

  dependsOn: [
    ManagedPrometheus
    ManagedPrometheusAlertsActionGroup
  ]
}
```

Note: Make sure to update these modules according to your requirements and remove module references that are not needed.

