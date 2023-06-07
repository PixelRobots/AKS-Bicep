param clusterName string
param nodepoolName string
@allowed([
  ''
  'System'
  'User'
])
param nodepoolMode string
param clusterLocation string
param clusterResourceId string
param newKubernetesVersion string


resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-11-01' existing = {
  name: clusterName
}

resource agentPool 'Microsoft.ContainerService/managedClusters/agentPools@2022-11-01' = {
  name: nodepoolName
  parent: aksCluster
  location: clusterLocation
  properties: {
    mode: !empty(nodepoolMode) ? nodepoolMode : null 
    id: clusterResourceId
    orchestratorVersion: newKubernetesVersion
  }
}
