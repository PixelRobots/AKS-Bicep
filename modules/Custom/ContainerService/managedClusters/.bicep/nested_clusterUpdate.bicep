param variables_clusterName string
param clusterLocation string
param clusterResourceId string
param newKubernetesVersion string

resource variables_cluster 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
  name: variables_clusterName
  location: clusterLocation
  properties: {
    id: clusterResourceId
    kubernetesVersion: newKubernetesVersion
  }
}
