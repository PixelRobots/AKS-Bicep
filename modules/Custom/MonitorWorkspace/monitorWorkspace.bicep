param name string
param tags object
param location string


resource monitorWorkspace 'microsoft.monitor/accounts@2021-06-03-preview' = {
  name: name
  location: location
  tags: tags
}


@description('The resource ID of the monitor workspace.')
output resourceId string = monitorWorkspace.id
