// AKS Cluster — Azure SRE Agent blue/green demo scenario
// Deploys a minimal AKS cluster with Container Insights and Application Insights.
// Run from within rg-webstore-aks:
//   az deployment group create \
//     --resource-group rg-webstore-aks \
//     --template-file scenarios/aks-blue-green/infra/aks-cluster.bicep \
//     --parameters clusterName=aks-webstore-demo location=eastus2

@description('Name of the AKS cluster')
param clusterName string = 'aks-webstore-demo'

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Number of system nodes')
param nodeCount int = 2

@description('VM size for system nodes (2 vCPU, 8 GB RAM — sufficient for demo)')
param nodeVmSize string = 'Standard_D2s_v3'

@description('Log Analytics workspace name (created alongside the cluster)')
param logAnalyticsWorkspaceName string = 'log-${clusterName}'

@description('Application Insights name for request telemetry')
param appInsightsName string = 'appi-${clusterName}'

// ── Log Analytics workspace ────────────────────────────────────────────────
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

// ── Application Insights (linked to Log Analytics) ─────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ── AKS Cluster ────────────────────────────────────────────────────────────
resource aks 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: clusterName
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'system'
        count: nodeCount
        vmSize: nodeVmSize
        mode: 'System'
        osType: 'Linux'
        enableAutoScaling: false
      }
    ]
    addonProfiles: {
      // Container Insights — gives SRE Agent pod logs and metrics via kubectl
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
    }
    networkProfile: {
      networkPlugin: 'azure'
      loadBalancerSku: 'standard'
    }
  }
}

// ── Outputs ────────────────────────────────────────────────────────────────
output clusterId string = aks.id
output clusterName string = aks.name
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
