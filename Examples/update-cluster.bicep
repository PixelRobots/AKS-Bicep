// This file operates at subscription level.
// This is a modular deployment. This file, 'main.bicep', will call bicep modules within the /modules directory.
// The only resources that will be directly deployed by this file will be the resource groups.

// This file can only be deployed at a subscription scope
targetScope = 'subscription'

/*
//Parameters and variables with default values where appropriate.
*/
@description('Azure Region to deploy the resources in.')
@allowed([
  'westeurope'
  'uksouth'
])
param location string = 'uksouth'

/*
// Azure Kubernetes Service Parameters
*/
@description('The name of the AKS cluster.')
param aksClusterName string

@description('The name of the resource group that has the AKS cluste.r')
param aksClusterResourceGroup string

@description('The Kubernetes version you would like to update to.')
param newKubernetesVersion string = '1.26.3'

@description('If set to true the node pools will also be updated.')
param includeNodepools bool = true


/*
// Nodepool parameters
*/
@description('Array of resource Groups.')
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Deployment modules start here. 
// Remember to update these to suit your requirements. Remove module references you don't need.

// Get exsiting resource values
resource AKSclusterResource 'Microsoft.ContainerService/managedClusters@2023-03-02-preview' existing = {
  scope: resourceGroup(aksClusterResourceGroup)
  name: aksClusterName
}


// Upgrade Control Plane
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

// Upgrade node pools
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

