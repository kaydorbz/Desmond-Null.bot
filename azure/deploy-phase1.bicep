param location string = resourceGroup().location

// Static Web App – will host acedefective.com
resource staticWebApp 'Microsoft.Web/staticSites@2022-03-01' = {
  name: 'acedefective-${uniqueString(resourceGroup().id)}'
  location: location
  sku: { tier: 'Free', name: 'Free' }
  properties: {
    branch: 'main'
  }
}

// Logic App – the ghost brain
resource logicApp 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'desmond-ghost-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    state: 'Enabled'
    definition: loadJsonContent('../logic-apps/phase1-workflow.json')
  }
}

// Outputs you’ll see after deploy
output siteUrl string = 'https://acedefective.com'  // after custom domain is added
output staticWebAppName string = staticWebApp.name
output logicAppName string = logicApp.name
