// Metric alert: AKS stub app error rate
// Fires when the number of failed HTTP requests (5xx) exceeds 1 in a 1-minute window.
// Targets the Application Insights resource created by aks-cluster.bicep.
//
// Deploy after the cluster Bicep:
//   az deployment group create \
//     --resource-group rg-webstore-aks \
//     --template-file scenarios/aks-blue-green/infra/monitoring/aks-error-rate-alert.bicep \
//     --parameters appInsightsName=appi-aks-webstore-demo

@description('Name of the Application Insights resource to monitor')
param appInsightsName string

@description('Alert severity (0=Critical, 1=Error, 2=Warning, 3=Info)')
param severity int = 2

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource failedRequestsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Failed Requests - ${appInsightsName}'
  location: 'global'
  properties: {
    description: 'Fires when the AKS stub app returns more than 1 failed request (5xx) in 1 minute. Used to trigger Azure SRE Agent investigation.'
    severity: severity
    enabled: true
    scopes: [appInsights.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighFailedRequests'
          criterionType: 'StaticThresholdCriterion'
          metricName: 'requests/failed'
          // NOTE: requests/failed only supports Count aggregation — do not change to Total
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 1
        }
      ]
    }
    autoMitigate: true
  }
}

output alertId string = failedRequestsAlert.id
output alertName string = failedRequestsAlert.name
