# AKS Deployment Failure — Investigation Runbook

**Scenario:** `aks-blue-green`  
**Failure mode:** Service selector pointing to broken green deployment (HTTP 503)  
**Target resource group:** `rg-webstore-aks`

---

## Symptoms

- `requests/failed` metric in App Insights spikes above threshold
- `POST /checkout` returns **503** with ~1.5 s latency
- `GET /health` still returns **200** (pods are healthy, not crashing)
- Azure Monitor fires: `Failed Requests - appi-aks-webstore-demo`

---

## Step 1: Confirm the failure

### Via Azure Monitor alert history

In the Azure Portal: **Monitor → Alerts → Alert history**. Look for `Failed Requests - appi-aks-webstore-demo` fired within the last hour.

### Via App Insights (KQL)

```kql
// Requests in the last 30 minutes, grouped by result code
requests
| where timestamp > ago(30m)
| summarize count() by resultCode
| order by count_ desc
```

Expected output after break: high count of `503`, normal baseline of `201`.

```kql
// Error spike timeline — correlate with deployment activity
requests
| where timestamp > ago(1h) and success == false
| summarize failures=count() by bin(timestamp, 1m)
| render timechart
```

### Via CLI — live checkout test

```bash
az aks get-credentials \
  --resource-group rg-webstore-aks \
  --name aks-webstore-demo \
  --overwrite-existing

SVC_IP=$(kubectl get service webstore-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s -w "\nHTTP %{http_code}\n" -X POST "http://$SVC_IP/checkout"
# HTTP 503 → failure confirmed
# HTTP 201 → system is healthy
```

---

## Step 2: Identify root cause

### Check the Service selector

```bash
kubectl get service webstore-svc -o jsonpath='{.spec.selector}'
# Broken state: {"app":"webstore","version":"green"}
# Healthy state: {"app":"webstore","version":"blue"}
```

### Inspect the active pods

```bash
kubectl get pods -l app=webstore -o wide
# Both webstore-blue-* and webstore-green-* pods should be Running
# If green pods are in CrashLoopBackOff, the issue is more severe (image/config problem)
```

### Check the broken pod's environment

```bash
# Find a green pod name
GREEN_POD=$(kubectl get pods -l app=webstore,version=green -o jsonpath='{.items[0].metadata.name}')

# Check the env var
kubectl exec $GREEN_POD -- env | grep DEMO_BROKEN_CHECKOUT
# Expected: DEMO_BROKEN_CHECKOUT=true ← root cause

# Check recent logs
kubectl logs $GREEN_POD --tail=50
```

### Check deployment history

The Service selector change is made via `kubectl`, which calls the Kubernetes API — it will **not** appear in the Azure Resource Group Activity Log (which tracks ARM operations only).

Instead, check these sources:

**GitHub Actions run history** — the `aks-demo-break` workflow is the only thing that patches the Service:
```bash
gh run list --workflow aks-demo-break.yml --limit 5
gh run view <run-id> --log
```

**Kubernetes Service events** — shows when the selector was last changed:
```bash
kubectl describe service webstore-svc
```

**Kubernetes audit logs** — if audit logging is enabled on the cluster, query via Log Analytics:
```kusto
AzureDiagnostics
| where Category == "kube-audit"
| where log_s contains "webstore-svc"
| order by TimeGenerated desc
| take 20
```

---

## Step 3: Remediation

### Rollback the Service selector (primary fix)

Patch the Service to route traffic back to the stable blue deployment:

```bash
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

Verify:
```bash
kubectl get service webstore-svc -o jsonpath='{.spec.selector}'
# Expected: {"app":"webstore","version":"blue"}

SVC_IP=$(kubectl get service webstore-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s -w "\nHTTP %{http_code}\n" -X POST "http://$SVC_IP/checkout"
# Expected: HTTP 201
```

### GitHub Actions reset workflow (alternative)

```bash
gh workflow run "AKS: Reset Deployment" -f environment=demo
```

### Prevent accidental re-break

If the green Deployment will remain in the cluster, consider scaling it down until the root cause (the broken config) is fixed:

```bash
kubectl scale deployment webstore-green --replicas=0
```

---

## Expected SRE Agent behavior

1. **Alert acknowledged** — agent picks up `Failed Requests - appi-aks-webstore-demo`
2. **App Insights query** — `CorrelateTimeSeries` shows error spike beginning at time T
3. **`kubectl get pods`** — both blue and green are Running (no crash loops)
4. **`kubectl describe service webstore-svc`** — selector shows `version=green`
5. **`kubectl exec` / `kubectl logs`** — green pods have `DEMO_BROKEN_CHECKOUT=true`
6. **Proposed action** — `kubectl patch service webstore-svc -p '{"spec":{"selector":{"version":"blue"}}}'`
7. **[Review mode]** You approve → agent executes
8. **Recovery confirmed** — agent verifies `/checkout` returns 201
9. **GitHub Issue created** — root cause, evidence, and timeline attached

---

## Monitoring reference

| Alert | Threshold | Evaluation | Window |
|-------|-----------|-----------|--------|
| `Failed Requests - appi-aks-webstore-demo` | `requests/failed` > 1 | Every 1 min | 1 min |

Deploy alert:
```bash
az deployment group create \
  --resource-group rg-webstore-aks \
  --template-file scenarios/aks-blue-green/infra/monitoring/aks-error-rate-alert.bicep \
  --parameters appInsightsName=appi-aks-webstore-demo
```

---

## Cost management

```bash
# Stop the cluster between sessions (no compute cost, persists config)
az aks stop --resource-group rg-webstore-aks --name aks-webstore-demo

# Resume
az aks start --resource-group rg-webstore-aks --name aks-webstore-demo
```
