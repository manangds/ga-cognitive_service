param environment string = 'PRD'
var projectName = 'AIRSS'

var vnetName = 'Vn-${projectName}-${environment}-01'
var subnetName2 = 'Sn-${projectName}-ApimOpenAI-${environment}-01'
var subnetName5 = 'Sn-${projectName}-Function-${environment}-01'

var openAIInstanceName = 'OpenAI-${projectName}-${environment}-01'

// === Generalized Ingestion runtime (MLGP function) ===
param generalizedIngestionOpenAIApiVersion string = '2025-04-14'
param generalizedIngestionOpenAIModel string = 'gpt-4.1'

// === Document Intelligence (Form Recognizer) ===
param docIntelSkuName string = 'S0'

// New Document Intelligence account name
var docIntelName = 'DI-${projectName}-${environment}-01'

// Azure AI Document Intelligence (formerly Form Recognizer)
resource docIntel 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: docIntelName
  location: resourceGroup().location
  tags: {
    'enterprise-env': toLower(environment)
  }
  sku: {
    name: docIntelSkuName
  }
  kind: 'FormRecognizer'
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource openAIInstance 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: openAIInstanceName
  location: resourceGroup().location
  sku: {
    name: 'S0'
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAIInstanceName
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      virtualNetworkRules: [
        {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName2, subnetName5)
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

// New Azure OpenAI deployment: gpt-4.1
resource openAIInstanceName_gpt4_1 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: openAIInstance
  name: 'gpt-4.1'
  sku: {
    name: 'GlobalStandard'
    capacity: 2000
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: generalizedIngestionOpenAIModel
      version: generalizedIngestionOpenAIApiVersion
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.DefaultV2'
  }
  dependsOn: [
    openAIInstance
  ]
}
