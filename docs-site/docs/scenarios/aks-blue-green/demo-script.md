---
sidebar_position: 2
title: "🎤 AKS Demo Script"
description: Step-by-step presenter guide for the AKS blue/green deployment demo.
---

# AKS Demo Script

A step-by-step presenter guide for running the AKS blue/green deployment demo live. Designed for a **10–15 minute** slot.

---

## Before the demo

Run through this checklist **the morning of** your presentation.

### Infrastructure health

```bash
# Verify the AKS cluster is running
az aks show \
  --resource-group rg-webstore-aks \
  --name aks-webstore-demo \
  --query powerState.code -o tsv
# Expected: Running

# Get credentials
az aks get-credentials \
  --resource-group rg-webstore-aks \
  --name aks-webstore-demo \
  --overwrite-existing

# Verify both deployments are healthy
kubectl get deployments
# Expected: webstore-blue (2/2), webstore-green (2/2)

# Verify Service is routing to blue
kubectl get service webstore-svc -o jsonpath='{.spec.selector}'
# Expected: {"app":"webstore","version":"blue"}

# Get the external IP and test checkout
SVC_IP=$(kubectl get service webstore-svc -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s -X POST http://$SVC_IP/checkout
# Expected: {"orderId":"order-...","status":"confirmed"} with HTTP 201
```

### SRE Agent health

1. Open [Azure Portal](https://portal.azure.com) → search **SRE Agent** → open `webstore-sre-agent`
2. Confirm status is **Active** (not "Building Knowledge Graph")
3. Open **Incident response plans** — confirm the plan targeting `rg-webstore-aks` is enabled
4. Run mode: set to **Review** for a live demo (you approve each action) or **Autonomous** for a fully automated show

### Reset to clean state

```bash
# Make sure Service is pointing at blue before the demo
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

Or use the `AKS: Reset Deployment` GitHub Actions workflow.

---

## The demo (10–15 min)

### Step 1: Set the scene (2 min)

> "We have an AKS cluster running a simple e-commerce checkout API. Two deployments are live — blue (v1, stable) and green (v2, the new release). Right now all traffic is on blue."

Show the audience:
- The running pods: `kubectl get pods -o wide`
- The Service selector: `kubectl get service webstore-svc -o yaml`
- A healthy checkout: `curl -X POST http://<SVC_IP>/checkout`

---

### Step 2: "Deploy" the broken green version (1 min)

> "We're going to roll out the new version. This is exactly what a CI/CD pipeline does — it shifts traffic to the new deployment."

Trigger the **`AKS: Break Deployment`** workflow in GitHub Actions (workflow dispatch), or run it directly:

```bash
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"green"}}}'
```

> "And just like that — 100% of traffic is now hitting green."

Show the first 503:
```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST http://<SVC_IP>/checkout
# HTTP 503
```

---

### Step 3: Watch the alert fire (1–2 min)

> "Azure Monitor is already watching this. Let's see what happens..."

Open **Azure Portal → Monitor → Alerts**. Within ~1 minute the `Failed Requests - appi-aks-webstore-demo` alert fires.

> "We didn't have to write a runbook, set up an on-call rotation, or build a custom script. Azure SRE Agent is already on this."

---

### Step 4: SRE Agent investigates (3–5 min)

Open the SRE Agent portal page. Show the active incident:

> "The agent acknowledged the alert. Watch what it does next..."

The agent will:
1. Query App Insights: `CorrelateTimeSeries` — spots the error spike at the exact time of the selector patch
2. Run `kubectl get pods` — both deployments are running, no crashes
3. Run `kubectl describe service webstore-svc` — sees selector is `version=green`
4. Run `kubectl logs` on a green pod — sees `DEMO_BROKEN_CHECKOUT=true` in the response
5. Propose remediation: **patch the Service selector back to `version=blue`**

> "It found the root cause in seconds. No one had to dig through logs at 3 AM."

---

### Step 5: Approve the fix (30 sec)

In **Review mode**: click **Approve** on the proposed kubectl patch.

> "In Autonomous mode, this would have already happened while we were still talking."

The agent executes:
```bash
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

---

### Step 6: Confirm recovery (1 min)

```bash
curl -s -w "\nHTTP %{http_code}\n" -X POST http://<SVC_IP>/checkout
# HTTP 201
```

> "Service is restored. But the story doesn't stop there."

---

### Step 7: GitHub Issue created (1 min)

Open GitHub → Issues. The agent created an issue with:
- Root cause summary
- Timeline of events
- Evidence (App Insights query results, kubectl output)
- Recommended permanent fix

> "The agent left a paper trail. The team wakes up, sees the issue, and immediately knows what happened and what to do."

---

## Key talking points

| Question | Answer |
|----------|--------|
| "Does it always work?" | Run mode controls this. Review = human in the loop. Autonomous = fully self-healing. |
| "What if the fix is wrong?" | Review mode lets you reject. The agent learns from feedback (persistent memory). |
| "Does it work with other Azure services?" | Yes — Container Apps, Functions, SQL, API Management, and more. AKS has native kubectl support. |
| "Does it integrate with existing tools?" | GitHub, Teams, Outlook, PagerDuty, ServiceNow — via connectors. Any custom API via MCP. |

---

## Cleanup

```bash
# Reset Service to blue after the demo
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"blue"}}}'

# Or use the workflow:
# gh workflow run "AKS: Reset Deployment" -f environment=demo
```

To save costs between sessions:
```bash
az aks stop --resource-group rg-webstore-aks --name aks-webstore-demo
# Restart before the next demo:
az aks start --resource-group rg-webstore-aks --name aks-webstore-demo
```
