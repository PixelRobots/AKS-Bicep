@description('The name of the Grafana resource to be created or updated.')
param name string

@description('The SKU name for the Grafana resource, determining the pricing tier and capabilities.')
param skuName string

@description('An array of existing Azure Monitor workspace integrations with the Grafana resource. This should include all current integrations to be preserved.')
param existingAzureMonitorWorkspaceIntegrations array

@description('The location where the Grafana resource will be deployed.')
param location string

@description('An array containing new Azure Monitor workspace integrations to be added to the Grafana resource.')
param newAzureMonitorWorkspaceIntegrations array

resource addAKSClusterToGrafana 'Microsoft.Dashboard/grafana@2023-09-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: union(existingAzureMonitorWorkspaceIntegrations, newAzureMonitorWorkspaceIntegrations)
    }
  }
}

