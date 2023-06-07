# Update an existing Azure Kubernetes Cluster (AKS)

`updateCluster.ps1` is a Bicep deployment script written in PowerShell. It deploys Azure resources based on the specified parameters.

## Parameters

- `subscriptionID` (string): The ID of the Azure subscription (mandatory).
- `location` (string): The Azure region for deploying the AKS cluster (mandatory, default: "West Europe").
- `aksClusterName` (string): The name of the AKS cluster (mandatory).
- `aksClusterResourceGroup` (string): The name of the resource group that contains the AKS cluster (mandatory).

## Update Process

To initiate the update, use the update switch. The script performs the following steps:

1. Sets the correct Azure subscription using the provided subscription ID.
2. Begins the deployment by creating a deployment ID using `New-Guid`.
3. Executes the deployment using the `az deployment sub create` command with the specified parameters.
   - The `--template-file` flag points to the Bicep template file `./update-cluster.bicep`.
   - The `--parameters` flag provides the values for the parameters `location`, `aksClusterName`, and `aksClusterResourceGroup`.
   - The `--confirm-with-what-if` flag enables a "What If" check for the deployment.
4. If the deployment fails, an error message is displayed. Otherwise, the deployment is considered successful.

> Note: Ensure that you have the Azure CLI (`az`) installed and authenticated before running this script.

## Example Usage

```powershell
.\deploy-aks-cluster.ps1 
-subscriptionID <string> 
-location <string> 
-aksClusterName <string> 
-aksClusterResourceGroup <string>
-deploy
```

Please replace the placeholder values with the appropriate information for your deployment.

> Note: This documentation assumes familiarity with PowerShell scripting and Azure resource deployment.


That's the documentation for the given PowerShell script in Markdown format. Feel free to modify it or add more details as needed.


<hr>
<br>

# Bicep File - update-cluster.bicep

fil;eThis Bicep file is used to update an Azure Kubernetes Services (AKS). It operates at the subscription level and is designed as a modular deployment. The main file, 'update-Cluster.bicep', calls Bicep modules within the `'/modules'` directory.

## Parameters

- `location` (string): Azure region to deploy the resources in.
- `aksClusterName` (string): Name of the AKS cluster.
- `aksClusterResourceGroup` (string): Name of the resource group that has the AKS cluster.
- `newKubernetesVersion` (string): Kubernetes version to update to (default: '1.26.3').
- `includeNodepools` (bool): If set to true, the node pools will also be updated.

## Nodepool Parameters

The `nodepoolArray` parameter is an array of resource groups, specifying the name and mode of each node pool.
> Note: If the node pool is a workload node pool please just use '' for the mode.
```bicep
param nodepoolArray array = [
  {
    name: 'systempool'
    mode: 'System'
  }
  {
    name: 'workloadpool'
    mode: ''
  }
]
```

## Deployment Modules

### Get Existing Resource Values

These resources are used within the Bicep template to reference existing resources and establish relationships with other resources or modules.

```bicep
resource AKSclusterResource 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' existing = {
  scope: resourceGroup(aksClusterResourceGroup)
  name: aksClusterName
}
```
<br>

### Update the AKS Control plane version, not the node pools
Upgrades the control plane of the AKS cluster to a specified Kubernetes version.

```bicep
module aksCluster_Update '../modules/Custom/ContainerService/managedClusters/.bicep/nested_clusterUpdate.bicep' = {
  name: 'aksUpdate--${uniqueString(aksClusterName)}'
  scope: resourceGroup(aksClusterResourceGroup)
  params: {
    variables_clusterName: aksClusterName
    clusterLocation: location
    clusterResourceId: AKSclusterResource.id
    newKubernetesVersion: newKubernetesVersion
  }
}
```
<br>

### Update the AKS node Pools from the nodepoolArray
Updates the node pools of the AKS cluster to the specified Kubernetes version. The number of modules created depends on the number of node pools in the `nodepoolArray` parameter.

```bicep
module Nodepool_updates '../modules/Custom/ContainerService/managedClusters/.bicep/nested_nodepoolUpdate.bicep' = [for (nodepool, i) in nodepoolArray: if (includeNodepools)  {
  name: 'nodepoolUpdate-${nodepool.name}'
  scope: resourceGroup(aksClusterResourceGroup)
  params: {
    clusterName: aksClusterName
    clusterLocation: location
    clusterResourceId: AKSclusterResource.id
    nodepoolName: nodepool.name
    nodepoolMode: nodepool.mode
    newKubernetesVersion: newKubernetesVersion
  }
  dependsOn: [
    aksCluster_Update
  ]
}]
```

<br>

Please note that you may need to customize the module paths and adjust the parameters to suit your specific requirements.

> Note: This documentation assumes familiarity with Bicep and Azure resource deployment.
