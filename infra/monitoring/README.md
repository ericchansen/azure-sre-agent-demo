# Monitoring Infrastructure

Bicep templates for alert rules that monitor the webstore application.

## Resources

| File | What it creates | Target RG |
|------|-----------------|-----------|
| `failed-requests-alert.bicep` | Metric alert: >3 failed requests in 5 min | `rg-webstore-staging` |

## Why this is separate from the SRE Agent infra

The SRE Agent's own infra (`infra/sre-agent/`) creates resources in `rg-webstore-sre-agent`, including the agent's own Application Insights (`app-insights-*`) for agent diagnostics.

The webstore's telemetry (requests, traces, exceptions) flows to `appi-webstore-staging` in `rg-webstore-staging` — a completely different App Insights resource. Alert rules that monitor the webstore must target this resource, so they live here.

## Deployment

Deployed automatically by the `deploy-monitoring.yml` GitHub Actions workflow on push to `main`.

Manual deployment:

```bash
az deployment group create \
  --resource-group rg-webstore-staging \
  --template-file infra/monitoring/failed-requests-alert.bicep \
  --parameters appInsightsName=appi-webstore-staging
```

## How it connects to the SRE Agent

```
Webstore 503s → appi-webstore-staging collects them
  → Metric alert fires (>3 failures in 5 min)
    → Azure Monitor alert instance created
      → SRE Agent picks it up (Azure Monitor incident platform)
        → Incident response plan routes to investigation
```
