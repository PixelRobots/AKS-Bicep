// This file operates at subscription level.
// This is a modular deployment. This file, 'main.bicep', will call bicep modules within the /modules directory.
// The only resources that will be directly deployed by this file will be the resource groups.

// This file can only be deployed at a subscription scope
targetScope = 'subscription'

/*
//Parameters and variables with default values where appropriate.
*/
@description('Logged in user details. Passed in from parent "deployNow.ps1" script.')
param updatedBy string = ''

@description('Environment Type: Test, Acceptance/UAT, Production, etc. Passed in from parent "deployNow.ps1" script.')
@allowed([
  'test'
  'dev'
  'prod'
])
param environmentName string = 'test'

@description('The customer name.')
param customerName string

@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'uksouth'
])
param location string = 'uksouth'

@description('Location shortcode. Used for end of resource names.')
param locationshortcode string

// Resource Tags
@description('Add tags as required as Name:Value')
param tags object = {
  Environment: environmentName
  Customer: customerName
  LastUpdatedOn: utcNow('d')
  LastDeployedBy: updatedBy
}

/*
// Resource Group parameters
*/
@description('Array of resource Groups.')
param resourceGroupArray array = [
  {
    name: 'rg-monitoring-${customerName}-${environmentName}-${locationshortcode}'
    location: location
  }
]


/*
// Monitoring Parameters
*/
// Log Analytics
@description('The name of the Log Analytics used for AKS.')
param aksLAWName string

@description('The name of the resource group that has the Log analaytics workspace connected to AKS')
param aksLAWResourceGroup string

// Enable Grafana
@description('If enabled deploy Grafana')
param enableGrafana bool = true

// Azure Monitor Workspace
param monitorWorspacename string = 'aks-monws-${customerName}-${environmentName}-${locationshortcode}'

@allowed([
  'eastus2euap'
  'centraluseuap'
  'centralus'
  'eastus'
  'eastus2'
  'northeurope'
  'southcentralus'
  'southeastasia'
  'uksouth'
  'westeurope'
  'westus'
  'westus2'
])
param azureMonitorWorkspaceLocation string = 'westeurope'

// Grafana
@minLength(2)
@maxLength(23)
@description('The resource name.')
param grafanaWorkspaceName string = take('gra${customerName}${environmentName}${locationshortcode}',23)

@allowed([
  'Standard'
])
param grafanaSKU string = 'Standard'

// Action Group
@description(' URI used for the action group to send Prometheus Alerts')
param webhookURI string = 'https://api.test.com'

/*
// Azure Kubernetes Service Parameters
*/
@description('The name of the AKS cluster.')
param aksClusterName string

@description('The name of the resource group that has the AKS cluster')
param aksClusterResourceGroup string



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deployment modules start here. 
// Remember to update these to suit your requirements. Remove module references you don't need.

// Get exsiting resource values
resource LAWResourceID 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  scope: resourceGroup(aksLAWResourceGroup)
  name: aksLAWName
}

resource AKSClusterResourceID 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' existing = {
  scope: resourceGroup(aksClusterResourceGroup)
  name: aksClusterName
}

// Deploy required Resource Groups
module resourceGroups '../modules/Resources/resourceGroups/main.bicep' = [for (resourceGroup, i) in resourceGroupArray: {
  name: 'rg-${i}-${customerName}-${environmentName}-${locationshortcode}'
  params: {
    name: resourceGroup.name
    location: resourceGroup.location
    tags: tags
  }
}]


// Deploy required Azure Monitor Workspace
module monitorWorkspace '../modules/Custom/MonitorWorkspace/monitorWorkspace.bicep' =  {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: monitorWorspacename
  params:{
  name: monitorWorspacename
  location: azureMonitorWorkspaceLocation
  tags: tags
  }

  dependsOn:[
    resourceGroups
  ]
}

// Deploy Azure Managed Grafana
module ManagedGrafana '../modules/Custom/ManagedGrafana/main.bicep' = if (enableGrafana) {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'ManagedGrafana'
  params:{
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


// Provide Grafana access to the AMW instance (https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-enable?tabs=bicep#limitation-with-bicep-deployment)
module roleAssignmentGrafanaAMW '../modules/Authorization/roleAssignments/resourceGroup/main.bicep' = if (enableGrafana) {
  name: 'Assign-Grafana-Monitoring-Data-Reader'
  scope: resourceGroup(resourceGroupArray[0].name)
  params: {
    principalId: ManagedGrafana.outputs.principalId
    roleDefinitionIdOrName: 'Monitoring Data Reader'
  }
}

// set up Azure Managed Prometheus
module ManagedPrometheus '../modules/Custom/ManagedPrometheus/main.bicep' =  {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'ManagedPrometheus'
  params:{
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

module ManagedPrometheusAlertsActionGroup '../modules/Insights/actionGroups/main.bicep' =  {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'ManagedPrometheusAlertsActionGroup'
  params:{
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


module ManagedPrometheusAlerts'../modules/Custom/ManagedPrometheus/.bicep/nested_prometheus_alerts.bicep' =  {
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
