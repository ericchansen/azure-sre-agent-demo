---
title: AKS Deployment Failure Investigation
scenario: aks-blue-green
failure_mode: service-selector-misconfiguration
severity: high
tags: [aks, kubernetes, deployment, blue-green, service-selector]
---

# AKS Deployment Failure — Knowledge Base

**Scenario:** `aks-blue-green`
**Failure mode:** Service selector pointing to broken green deployment (HTTP 503)
**Target resource group:** `rg-webstore-aks`

## Symptoms

- `requests/failed` metric in App Insights spikes above threshold
- `POST /checkout` returns **503** with ~1.5 s latency
- `GET /health` still returns **200** — pods are healthy, not crashing
- Azure Monitor fires: `Failed Requests - appi-aks-webstore-demo`

> **Key distinction:** healthy `/health` + failing `/checkout` indicates a
> configuration issue, not a crash or resource exhaustion.

## Root Cause Pattern

The Kubernetes Service `webstore-svc` selector has been patched from
`version: blue` (stable) to `version: green` (broken). The green
deployment has the environment variable `DEMO_BROKEN_CHECKOUT=true`, which
causes the application to return 503 on the `/checkout` endpoint.

Both blue and green pods remain Running — the issue is traffic routing,
not pod health.

## Investigation Commands

### 1. Confirm error spike (App Insights KQL)

```kql
requests
| where timestamp > ago(30m)
| summarize count() by resultCode
| order by count_ desc
```

Expected: high count of `503`, normal baseline of `201`.

### 2. Error timeline for correlation

```kql
requests
| where timestamp > ago(1h) and success == false
| summarize failures=count() by bin(timestamp, 1m)
| render timechart
```

### 3. Check service selector

```bash
kubectl get service webstore-svc -o jsonpath='{.spec.selector}'
```

| State   | Selector value                              |
|---------|---------------------------------------------|
| Healthy | `{"app":"webstore","version":"blue"}`        |
| Broken  | `{"app":"webstore","version":"green"}`       |

### 4. Inspect pod status

```bash
kubectl get pods -l app=webstore -o wide
```

Both `webstore-blue-*` and `webstore-green-*` pods should be Running.

### 5. Confirm broken environment variable

```bash
GREEN_POD=$(kubectl get pods -l app=webstore,version=green \
  -o jsonpath='{.items[0].metadata.name}')
kubectl exec $GREEN_POD -- env | grep DEMO_BROKEN_CHECKOUT
```

Expected output: `DEMO_BROKEN_CHECKOUT=true`

### 6. Check green pod logs

```bash
kubectl logs $GREEN_POD --tail=50
```

Look for 503 responses on `/checkout` in recent log entries.

## Remediation

Patch the Service selector to route traffic back to the stable blue
deployment:

```bash
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

This takes effect immediately — Kubernetes updates the Endpoints object
and new connections route to blue pods within seconds.

## Verification

**All three checks must pass before the incident is considered resolved.**

### 1. Confirm selector updated

```bash
kubectl get service webstore-svc -o jsonpath='{.spec.selector}'
# Expected: {"app":"webstore","version":"blue"}
```

### 2. Test the checkout endpoint

```bash
SVC_IP=$(kubectl get service webstore-svc \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s -w "\nHTTP %{http_code}\n" -X POST "http://$SVC_IP/checkout"
# Expected: HTTP 201
```

### 3. Confirm errors stopped in App Insights

Re-run the KQL query from step 1. The 503 count should drop to zero
within 1–2 minutes of the patch.

## Monitoring Reference

| Alert | Threshold | Evaluation | Window |
|-------|-----------|------------|--------|
| `Failed Requests - appi-aks-webstore-demo` | `requests/failed` > 1 | Every 1 min | 1 min |
