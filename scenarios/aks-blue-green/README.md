# Scenario: AKS Blue/Green Deployment

> ⚠️ **This scenario is under construction.** Infrastructure and workflows coming soon.

A "green" deployment of a stub Node.js app is rolled out to an AKS cluster. The green build deliberately fails (via `DEMO_BROKEN_CHECKOUT=true`). The Kubernetes Service selector is patched to route traffic to green, causing an error rate spike. Azure SRE Agent detects the spike via Container Insights and App Insights, rolls the Service selector back to blue, and creates a GitHub Issue with root cause analysis.

---

## Demo flow

| Step | What happens | Who does it |
|------|-------------|-------------|
| **1. Baseline** | Service selector points to `version: blue` (stable). All requests succeed. | The cluster |
| **2. Break** | `aks-demo-break` workflow patches Service selector to `version: green` (broken). Error rate spikes. | You (one-click workflow) |
| **3. Detection** | SRE Agent sees error rate spike via Container Insights + App Insights. | Azure SRE Agent |
| **4. Investigation** | Agent runs `kubectl get pods`, `kubectl logs`, correlates with deployment history. | Azure SRE Agent |
| **5. Remediation** | Agent patches Service selector back to `version: blue`. | Azure SRE Agent |
| **6. GitHub Issue** | Agent creates an issue with root cause, pod logs, and trace IDs. | Azure SRE Agent |

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│  AKS Cluster: aks-webstore   (rg-webstore-aks)  │
│                                                  │
│  webstore-blue  (v1-stable)   ← 100% traffic    │
│  webstore-green (v2-broken)   ← 0% traffic       │
│  webstore-svc   selector: version=blue           │
│                                                  │
│  Container Insights + App Insights               │
└──────────────────────┬───────────────────────────┘
                       │ alerts on error rate spike
                       ▼
          Azure SRE Agent (shared, rg-webstore-sre-agent)
                       │
             kubectl patch service
             GitHub Issue created
```

---

## Files in this scenario

| Path | Description |
|------|-------------|
| `app/` | Stub Node.js app (`/health`, `/checkout` endpoints) |
| `infra/aks-cluster.bicep` | Minimal AKS cluster with Container Insights |
| `infra/monitoring/` | Error rate metric alert Bicep |
| `k8s/blue-deployment.yaml` | Stable deployment (v1-stable image) |
| `k8s/green-deployment.yaml` | Broken deployment (v2-broken image, `DEMO_BROKEN_CHECKOUT=true`) |
| `k8s/service.yaml` | Service with `version: blue` selector |
| `runbooks/aks-deployment-failure.md` | Investigation and remediation runbook |

---

## Setup

### Prerequisites

- AKS cluster deployed via `infra/aks-cluster.bicep` (resource group: `rg-webstore-aks`)
- `acrwebstorestaging.azurecr.io/aks-stub:v1` image built and pushed
- ACR pull access granted to AKS: `az aks update --attach-acr acrwebstorestaging ...`
- GitHub Actions `demo` environment with variables `AKS_CLUSTER_NAME` and `AKS_RESOURCE_GROUP`

### 1. Get cluster credentials

```bash
az aks get-credentials --resource-group rg-webstore-aks --name aks-webstore-demo
```

### 2. Create the App Insights secret

The deployments read the Application Insights connection string from a Kubernetes Secret.
Create it before applying the manifests:

```bash
kubectl create secret generic appi-connection-string \
  --from-literal=connectionString="<APPLICATIONINSIGHTS_CONNECTION_STRING>"
```

Get the connection string from the Bicep deployment output:

```bash
az deployment group show \
  --resource-group rg-webstore-aks \
  --name <deployment-name> \
  --query properties.outputs.appInsightsConnectionString.value -o tsv
```

### 3. Apply Kubernetes manifests

```bash
kubectl apply -f scenarios/aks-blue-green/k8s/
```

### 4. Deploy the metric alert

```bash
az deployment group create \
  --resource-group rg-webstore-aks \
  --template-file scenarios/aks-blue-green/infra/monitoring/aks-error-rate-alert.bicep \
  --parameters appInsightsName=appi-aks-webstore-demo
```

