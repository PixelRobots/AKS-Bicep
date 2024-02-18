# Update Grafana Integrations with Azure Monitor Workspaces

`update-Grafana-integrations.ps1` is a PowerShell deployment script designed to update Grafana workspace integrations with Azure Monitor Workspaces. This script facilitates the automation of integrating Azure Monitor Workspaces into an existing Grafana workspace, enhancing monitoring and visualization capabilities.

## Parameters

The script requires the following parameters:

- `subscriptionID` (string): Azure subscription ID where the resources are located (mandatory).
- `location` (string): Azure region for the deployment (mandatory, default: "uksouth").
- `azureMonitorWorkspaceName` (string): Name of the Azure Monitor Workspace to be integrated (mandatory).
- `azureMonitorWorkspaceResourceGroup` (string): Resource group of the Azure Monitor Workspace (mandatory).
- `grafanaWorkspaceName` (string): Name of the Grafana Workspace to be updated (mandatory).
- `grafanaWorkspaceResourceGroup` (string): Resource group of the Grafana Workspace (mandatory).

## Deployment Process

To deploy the integration, ensure the `$deploy` switch is set. The script executes the following steps:

1. Sets the Azure subscription context to the provided `subscriptionID`.
2. Generates a unique deployment name using `New-Guid`.
3. Initiates the Bicep deployment with `az deployment sub create`, specifying the `update-Grafana-integrations.bicep` file and passing the necessary parameters.
4. Performs a "What-If" analysis to preview changes.
5. Upon successful deployment, integrates the specified Azure Monitor Workspace with the Grafana workspace.

> **Note**: Ensure the Azure CLI is installed and authenticated before running the script.

## Example Usage

```powershell
.\update-Grafana-integrations.ps1 `
-subscriptionID "your_subscription_id" `
-location "uksouth" `
-azureMonitorWorkspaceName "your_monitor_workspace_name" `
-azureMonitorWorkspaceResourceGroup "your_monitor_workspace_rg" `
-grafanaWorkspaceName "your_grafana_workspace_name" `
-grafanaWorkspaceResourceGroup "your_grafana_workspace_rg" `
-deploy
```

Replace placeholder values with actual information for your deployment.

---

# Bicep File - update-Grafana-Integrations.bicep

This Bicep file facilitates the integration of Azure Monitor Workspaces with Grafana by updating Grafana workspace settings and configurations. It operates within the specified subscription and utilizes modular deployment strategies for scalable and manageable code.

## Parameters

- `azureMonitorWorkspaceName` (string): The name of the Azure Monitor Workspace for integration.
- `azureMonitorWorkspaceResourceGroup` (string): The resource group of the Azure Monitor Workspace.
- `grafanaWorkspaceName` (string): The name of the Grafana Workspace to be updated.
- `grafanaWorkspaceResourceGroup` (string): The resource group of the Grafana Workspace.
- `location` (string): Deployment region, defaulting to "uksouth".

## Resources and Modules

### Existing Resources

- **Grafana Workspace**: Identified within the specified resource group to update its integration settings.
- **Azure Monitor Workspace**: Specified for integration with the Grafana workspace.

### Update Grafana Integrations Module

Updates the Grafana workspace's integrations to include the specified Azure Monitor Workspace, enabling enhanced monitoring and data visualization capabilities.

### Role Assignment Module

Grants the Grafana workspace necessary permissions to access Azure Monitor Workspace data, ensuring secure and seamless integration.

## Deployment Modules

### Get Existing Resource Values

Within the Bicep template, existing resources are referenced to retrieve their values and establish relationships for the integration process. These references are crucial for identifying the current state and configurations of Grafana and Azure Monitor Workspaces.

```bicep
resource existingGrafana 'Microsoft.Dashboard/grafana@2023-09-01' existing = {
  scope: resourceGroup(grafanaWorkspaceResourceGroup)
  name: grafanaWorkspaceName
}

resource existingAzureMonitorWorkSpace 'Microsoft.Monitor/accounts@2023-04-03' existing = {
  scope: resourceGroup(azureMonitorWorkspaceResourceGroup)
  name: azureMonitorWorkspaceName
}
```

### Update Grafana Integrations

The main goal of the deployment is to update the Grafana workspace integrations to include the specified Azure Monitor Workspace. This is achieved by passing the new integration details to the Grafana workspace.

```bicep
var newAzureMonitorWorkspaceIntegrations = [{
  azureMonitorWorkspaceResourceId: existingAzureMonitorWorkSpace.id
}]

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
```

### Role Assignment for Grafana Access to Azure Monitor Workspace

To ensure Grafana has the necessary permissions to access data from the Azure Monitor Workspace, a role assignment is created. This step is vital for secure and seamless integration between Grafana and Azure Monitor Workspaces.

```bicep
module roleAssignmentGrafanaAMW '../modules/Authorization/roleAssignments/resourceGroup/main.bicep' = {
  scope: resourceGroup(azureMonitorWorkspaceResourceGroup)
  name: 'Assign-Grafana-Monitoring-Data-Reader-${uniqueString(grafanaWorkspaceResourceGroup, azureMonitorWorkspaceResourceGroup)}'
  params: {
    principalId: existingGrafana.identity.principalId
    roleDefinitionIdOrName: 'Monitoring Data Reader'
  }
}
```

This documentation outlines the deployment modules used for integrating Azure Monitor Workspace with Grafana, demonstrating the retrieval of existing resource values, updating Grafana integrations, and managing role assignments for access permissions.

> **Note**: Adapt module paths and parameter values as necessary to align with your deployment specifics. Familiarity with Bicep, Azure CLI, and Azure resource management is assumed.