targetScope = 'resourceGroup'

param location string = resourceGroup().location
param groqApiKey string = ''
param threadsAccessToken string = ''

// Key Vault – stores both secrets securely
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'desmond-kv-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

resource groqSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'groq-api-key'
  properties: { value: groqApiKey }
}

resource threadsSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'threads-token'
  properties: { value: threadsAccessToken }
}

// Static Web App – acedefective.com
resource site 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'acedefective-${uniqueString(resourceGroup().id)}'
  location: location
  sku: { tier: 'Free', name: 'Free' }
  properties: { branch: 'main' }
}

// Logic App – the ghost (Groq live generation)
resource logic 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'desmond-ghost-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('../logic-apps/phase1-live-groq.json')
    parameters: {
      '$connections': {
        value: {
          groq: { connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/groq', connectionName: 'groq', id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/groq' }
          threads: { connectionId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Web/connections/threads', connectionName: 'threads', id: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Web/locations/${location}/managedApis/threads' }
        }
      }
    }
  }
}

output siteUrl string = 'https://${site.properties.defaultHostname}'
output logicAppName string = logic.name
output keyVaultName string = kv.name
