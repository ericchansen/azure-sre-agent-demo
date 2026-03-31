// Metric alert for failed webstore requests
// Deploys to rg-webstore-staging, targeting appi-webstore-staging
//
// This is a deterministic threshold alert (>1 failed request in 1 min)
// that fires near-instantly on low-traffic demo apps. The ML-based Failure
// Anomalies smart detection in the SRE Agent's own App Insights may
// not fire without sufficient baseline traffic.
//
// When this alert fires, the SRE Agent picks it up via Azure Monitor
// and the incident response plan routes it for automatic investigation.

targetScope = 'resourceGroup'

@description('Name of the Application Insights resource to monitor')
param appInsightsName string = 'appi-webstore-staging'

@description('Failure threshold — alert fires when failed requests exceed this count in the window')
param failureThreshold int = 1

// Reference the existing Application Insights resource
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

// Metric alert: fires when total failed requests > threshold in a 1-minute window
// Evaluated every 1 minute — this is the fastest Azure Monitor supports
resource failedRequestsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Failed Requests - ${appInsightsName}'
  location: 'Global'
  properties: {
    description: 'Fires when more than ${failureThreshold} failed request(s) occur in a 1-minute window. Designed for near-instant demo triggering — the ML-based Failure Anomalies detector may not fire on low-traffic apps.'
    severity: 3
    enabled: true
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    scopes: [
      applicationInsights.id
    ]
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailedRequests'
          metricName: 'requests/failed'
          metricNamespace: 'microsoft.insights/components'
          operator: 'GreaterThan'
          threshold: failureThreshold
          timeAggregation: 'Count'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

output alertName string = failedRequestsAlert.name
output alertId string = failedRequestsAlert.id
