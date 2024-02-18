// This file can only be deployed at a subscription scope
targetScope = 'subscription'

@description('The name of the Azure Monitor Workspace to be integrated.')
param azureMonitorWorkspaceName string

@description('The resource group where the Azure Monitor Workspace is located.')
param azureMonitorWorkspaceResourceGroup string

@description('The name of the Grafana Workspace to be updated.')
param grafanaWorkspaceName string

@description('The resource group where the Grafana Workspace is located.')
param grafanaWorkspaceResourceGroup string

@description('The location for the Grafana resource deployment, defaulting to "uksouth".')
param location string = 'uksouth'

// Resources representing existing instances
resource existingGrafana 'Microsoft.Dashboard/grafana@2023-09-01' existing = {
  scope: resourceGroup(grafanaWorkspaceResourceGroup)
  name: grafanaWorkspaceName
}

resource existingAzureMonitorWorkSpace 'Microsoft.Monitor/accounts@2023-04-03' existing = {
  scope: resourceGroup(azureMonitorWorkspaceResourceGroup)
  name: azureMonitorWorkspaceName
}

// Variables with descriptions
// Fetches the current Azure Monitor Workspace integrations from the existing Grafana Workspace
var azureMonitorWorkspaceIntegrations = existingGrafana.properties.grafanaIntegrations.azureMonitorWorkspaceIntegrations

// Prepares a new integration object with the Azure Monitor Workspace resource ID
var newAzureMonitorWorkspaceIntegrations = [{
  azureMonitorWorkspaceResourceId: existingAzureMonitorWorkSpace.id
}]

// Module to update Grafana integrations
module updateGrafana '../modules/Custom/ManagedGrafana/update-grafana-integrations/main.bicep' = {
  scope: resourceGroup(grafanaWorkspaceResourceGroup)
  name: 'UpdateGrafanaWithAzureMonitorIntegration-${uniqueString(grafanaWorkspaceName, azureMonitorWorkspaceName)}'
  params: {
    name: grafanaWorkspaceName
    location: location
    skuName: existingGrafana.sku.name
    existingAzureMonitorWorkspaceIntegrations: azureMonitorWorkspaceIntegrations
    newAzureMonitorWorkspaceIntegrations: newAzureMonitorWorkspaceIntegrations
  }
}

// Provide Grafana access to the AMW instance (https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/prometheus-metrics-enable?tabs=bicep#limitation-with-bicep-deployment)
module roleAssignmentGrafanaAMW '../modules/Authorization/roleAssignments/resourceGroup/main.bicep' = {
  scope: resourceGroup(azureMonitorWorkspaceResourceGroup)
  name: 'Assign-Grafana-Monitoring-Data-Reader'
  params: {
    principalId: existingGrafana.identity.principalId
    roleDefinitionIdOrName: 'Monitoring Data Reader'
  }
}
