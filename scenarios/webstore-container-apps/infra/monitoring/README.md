# Monitoring Infrastructure

Bicep templates for alert rules that monitor the webstore application.

## Resources

| File | What it creates | Target RG |
|------|-----------------|-----------|
| `failed-requests-alert.bicep` | Metric alert: >1 failed request in 1 min | Your demo resource group |

## Why this is separate from the SRE Agent infra

The SRE Agent's own infra (`infra/sre-agent/`) creates resources in `rg-webstore-sre-agent`, including the agent's own Application Insights (`app-insights-*`) for agent diagnostics.

The webstore's telemetry (requests, traces, exceptions) flows to the Application Insights resource attached to your demo environment (for example, `appi-webstore-demo` in `rg-webstore-demo`) — a completely different App Insights resource from the agent's own diagnostics. Alert rules that monitor the webstore must target that resource, so they live here.

## Deployment

Deployed automatically by the `webstore-deploy-monitoring.yml` GitHub Actions workflow on push to `main`. The workflow reads `RESOURCE_GROUP` and `APP_INSIGHTS_NAME` from GitHub Actions variables so the repo does not hardcode a specific environment name.

Manual deployment:

```bash
az deployment group create \
  --resource-group <YOUR_DEMO_RESOURCE_GROUP> \
  --template-file scenarios/webstore-container-apps/infra/monitoring/failed-requests-alert.bicep \
  --parameters appInsightsName=<YOUR_APP_INSIGHTS_NAME>
```

## How it connects to the SRE Agent

```
Webstore 503s → <YOUR_APP_INSIGHTS_NAME> collects them
  → Metric alert fires (>1 failure in 1 min)
    → Azure Monitor alert instance created
      → SRE Agent picks it up (Azure Monitor incident platform)
        → Incident response plan routes to investigation
```
