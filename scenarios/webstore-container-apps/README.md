# Scenario: Webstore on Azure Container Apps

A live e-commerce storefront — **[Cacao & Co.](https://github.com/ericchansen/webstore)** — runs on Azure Container Apps, fully instrumented with OpenTelemetry. A single "bad deployment" sets an env var that makes the checkout API start returning **503**. Azure SRE Agent detects the spike, investigates App Insights traces, and rolls back the change.

> 📖 **[Full docs →](https://ericchansen.github.io/azure-sre-agent-demo/docs/scenarios/webstore-container-apps/architecture)**

---

## Demo flow

| Step | What happens | Who does it |
|------|-------------|-------------|
| **1. Healthy baseline** | Visitors browse products, add to cart, complete checkout. Telemetry flows to App Insights. | The app |
| **2. Break checkout** | `DEMO_BROKEN_CHECKOUT=true` — checkout returns **503** with a 1.5 s delay. | You (one-click workflow) |
| **3. Detection** | SRE Agent sees the spike in 503s and failed dependency calls. | Azure SRE Agent |
| **4. Investigation** | Agent correlates logs, metrics, traces, and maps the failure back to source code via GitHub. | Azure SRE Agent |
| **5. Remediation** | Agent recommends (Review) or executes (Autonomous) a rollback of the env var. | Azure SRE Agent |
| **6. Recovery** | Checkout returns to 201. | The app |

---

## Azure resources

| Resource | Type | Resource Group |
|----------|------|---------------|
| `ca-webstore-prod` | Container App | `rg-webstore-prod` |
| `appi-webstore-prod` | Application Insights | `rg-webstore-prod` |
| `Failed Requests - appi-webstore-prod` | Metric Alert | `rg-webstore-prod` |

The SRE Agent is shared — see [`infra/sre-agent/`](../../infra/sre-agent/README.md).

---

## GitHub Actions variables

**Secrets** (per environment):
| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID (federated credential) |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription containing the Container App |

**Variables** (per environment):
| Variable | Example |
|----------|---------|
| `CONTAINER_APP_NAME` | `ca-webstore-prod` |
| `RESOURCE_GROUP` | `rg-webstore-prod` |
| `APP_INSIGHTS_NAME` | `appi-webstore-prod` |
| `TEST_PRODUCT_ID` | Real seeded product CUID, e.g. `cmmy0uf9f0006aoud83hpuo94` |

**Repository-level variables** (must be repo-level, not environment-scoped):
| Variable | Purpose | Example |
|----------|---------|---------|
| `DEMO_WORKFLOW_ENVIRONMENT` | Selects the GitHub Actions environment for `webstore-deploy-monitoring`. | `demo` |

---

## Workflows

```bash
# Break checkout (generates baseline traffic, then breaks)
gh workflow run "Webstore: Break Checkout" -f environment=demo

# Reset checkout
gh workflow run "Webstore: Reset Checkout" -f environment=demo

# Deploy monitoring alert
gh workflow run "Webstore: Deploy Monitoring Infrastructure"
```

---

## Monitoring

Metric alert: [`infra/monitoring/failed-requests-alert.bicep`](infra/monitoring/failed-requests-alert.bicep)

Triggers when `requests/failed` count > 1 in a 1-minute window. Deploy via the `webstore-deploy-monitoring` workflow or manually:

```bash
az deployment group create \
  --resource-group rg-webstore-prod \
  --template-file scenarios/webstore-container-apps/infra/monitoring/failed-requests-alert.bicep \
  --parameters appInsightsName=appi-webstore-prod
```

---

## Runbooks

| Runbook | When to use |
|---------|-------------|
| [`runbooks/frontend-failure-investigation.md`](runbooks/frontend-failure-investigation.md) | SRE Agent is investigating a frontend failure; use as a reference for expected investigation steps |
