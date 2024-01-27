# AKS Run Command Script

An Azure CLI Deployment Script that allows you to deploy a helm chart on to a Kubernetes cluster.

## Details

AKS run command allows you to remotely invoke commands in an AKS cluster through the AKS API. This module makes use of a custom script to expose this capability in a Bicep accessible module.
This module configures the required permissions so that you do not have to configure the identity although you can use an existing one.

## Parameters

| Name                                       | Type     | Required | Description                                                                                                   |
| :----------------------------------------- | :------: | :------: | :------------------------------------------------------------------------------------------------------------ |
| `aksName`                                  | `string` | Yes      | The name of the Azure Kubernetes Service                                                                      |
| `location`                                 | `string` | Yes      | The location to deploy the resources to                                                                       |
| `forceUpdateTag`                           | `string` | No       | How the deployment script should be forced to execute                                                         |
| `rbacRolesNeeded`                          | `array`  | No       | An array of Azure RoleIds that are required for the DeploymentScript resource                                 |
| `newOrExistingManagedIdentity`             | `string` | No       | Create "new" or use "existing" Managed Identity. Default: new                                                 |
| `managedIdentityName`                      | `string` | No       | Name of the Managed Identity resource                                                                         |
| `existingManagedIdentitySubId`             | `string` | No       | For an existing Managed Identity, the Subscription Id it is located in                                        |
| `existingManagedIdentityResourceGroupName` | `string` | No       | For an existing Managed Identity, the Resource Group it is located in                                         |
| `initialScriptDelay`                       | `string` | No       | A delay before the script import operation starts. Primarily to allow Azure AAD Role Assignments to propagate |
| `cleanupPreference`                        | `string` | No       | When the script resource is cleaned up                                                                        |
| `isCrossTenant`                            | `bool`   | No       | Set to true when deploying template across tenants                                                            |
| `helmRepo`                                 | `string` | Yes      | The name of the Helm repository                                                                               |
| `helmRepoURL`                              | `string` | Yes      | The URL of the Helm repository                                                                                |
| `helmApp`                                  | `string` | Yes      | The specific Helm chart to be used from the repository                                                        |
| `helmAppName`                              | `string` | Yes      | The name to assign to the deployed Helm application                                                           |
| `helmAppParams`                            | `string` | No       | Additional parameters for the Helm deployment command, such as namespace creation and naming                 |
| `helmAppValues`                            | `string` | No       | A base64 encoded string of the helm values file                                                               |

## Outputs

| Name            | Type    | Description                                                         |
| :-------------- | :-----: | :------------------------------------------------------------------ |
| `commandOutput` | `array` | Array of command output from each Deployment Script AKS run command |

## Examples

### Automatically create managed identity and RBAC

```bicep
module InstallInternalNginxIngress '../modules/Custom/deployment-scripts/aks-helm-install/main.bicep' = {
  name: 'Install-Internal-Ingress'
  params: {
    aksName: aksClusterName
    location: location
    newOrExistingManagedIdentity: 'new'
    helmRepo: 'ingress-nginx'
    helmRepoURL: 'https://kubernetes.github.io/ingress-nginx'
    helmApp: 'ingress-nginx/ingress-nginx'
    helmAppName: 'internal-ingress'
    helmAppParams: '--namespace internal-ingress --create-namespace'
    helmAppValues: loadFileAsBase64('../yaml/internalIngress.yaml')
  }
  dependsOn: [
    aksCluster
  ]
}
```

### Using an existing managed identity

When working with an existing managed identity that has the correct RBAC, you can opt out of new RBAC assignments and set the initial delay to zero.

```bicep
module InstallInternalNginxIngress '../modules/Custom/deployment-scripts/aks-helm-install/main.bicep' = {
  scope: resourceGroup(resourceGroupArray[0].name)
  name: 'Install-Internal-Ingress'
  params: {
    aksName: aksClusterName
    location: location
    newOrExistingManagedIdentity: 'existing'
    managedIdentityName: enabledInternalIngress ? aksRunMID.name : ''
    existingManagedIdentitySubId: subscription().subscriptionId
    existingManagedIdentityResourceGroupName: resourceGroupArray[0].name
    helmRepo: 'ingress-nginx'
    helmRepoURL: 'https://kubernetes.github.io/ingress-nginx'
    helmApp: 'ingress-nginx/ingress-nginx'
    helmAppName: 'internal-ingress'
    helmAppParams: '--namespace internal-ingress --create-namespace'
    helmAppValues: loadFileAsBase64('../yaml/internalIngress.yaml')
  }
  dependsOn: [
    aksCluster
  ]
}
```