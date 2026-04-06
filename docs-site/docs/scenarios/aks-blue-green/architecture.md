---
sidebar_position: 1
title: "AKS Blue/Green — Architecture"
description: How the AKS blue/green demo scenario works with Azure SRE Agent.
---

# Architecture: AKS Blue/Green Deployment

## System diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                     rg-webstore-aks (Azure)                          │
│                                                                      │
│   ┌───────────────────────────────────────────────────────────┐      │
│   │                AKS Cluster: aks-webstore-demo             │      │
│   │                                                           │      │
│   │   ┌──────────────────┐     ┌──────────────────────┐       │      │
│   │   │  webstore-blue   │     │  webstore-green      │       │      │
│   │   │  version: blue   │     │  version: green      │       │      │
│   │   │  (stable)        │     │  (BROKEN_CHECKOUT=   │       │      │
│   │   │  → 201 ✅         │     │   true → 503 ❌)      │       │      │
│   │   └──────────────────┘     └──────────────────────┘       │      │
│   │           │  ← selector: version=blue (default)            │      │
│   │           ▼                                                │      │
│   │   ┌────────────────────────────────┐                       │      │
│   │   │  Service: webstore-svc         │                       │      │
│   │   │  selector: version=blue        │ ← the demo switch     │      │
│   │   └───────────────┬────────────────┘                       │      │
│   └───────────────────┼───────────────────────────────────────┘      │
│                       │                                              │
│   ┌───────────────────▼───────────────────────────────────────┐      │
│   │  Application Insights (appi-aks-webstore-demo)            │      │
│   │  Container Insights (via omsagent addon)                  │      │
│   └───────────────────┬───────────────────────────────────────┘      │
│                       │ alert: requests/failed > 1 in 1 min          │
└───────────────────────┼──────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────────────────┐
│  rg-webstore-sre-agent   (shared SRE Agent)                          │
│                                                                      │
│  1. Alert acknowledged                                               │
│  2. App Insights queried: CorrelateTimeSeries (error spike at T)     │
│  3. kubectl get pods → green pods returning 503                      │
│  4. kubectl logs webstore-green-xxx → DEMO_BROKEN_CHECKOUT=true      │
│  5. Proposes: kubectl patch service webstore-svc                     │
│     (selector version=green → version=blue)                          │
│  [Approve] → rollback executes                                       │
│  6. GitHub Issue created with root cause + evidence                  │
└──────────────────────────────────────────────────────────────────────┘
```

## How the demo break works

The "break" is a **Service selector patch**, not a code change:

```bash
# Break: route traffic to the broken green deployment
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"green"}}}'

# Reset: route traffic back to the stable blue deployment
kubectl patch service webstore-svc \
  -p '{"spec":{"selector":{"version":"blue"}}}'
```

Both the blue and green Deployments run the same container image. The difference is a single environment variable: `DEMO_BROKEN_CHECKOUT=true` in the green Deployment spec causes the `/checkout` endpoint to return **503** with a 1.5 s delay.

## Why this pattern?

- **Fast on stage** — the selector patch takes under 5 seconds; no redeployment needed
- **Realistic** — simulates a "misconfigured rollout got all the traffic" scenario
- **Reversible** — SRE Agent can execute the exact same `kubectl patch` command to roll back
- **Repeatable** — run it as many times as you need

## Azure resources

| Resource | Type | Purpose |
|----------|------|---------|
| `aks-webstore-demo` | AKS Managed Cluster | Runs both deployments |
| `log-aks-webstore-demo` | Log Analytics Workspace | Container Insights data |
| `appi-aks-webstore-demo` | Application Insights | HTTP request telemetry (OTEL) |
| `Failed Requests - appi-aks-webstore-demo` | Metric Alert | Triggers SRE Agent investigation |

The SRE Agent itself lives in `rg-webstore-sre-agent` and is shared across all scenarios.

## CI/CD

| Workflow | Purpose |
|----------|---------|
| `aks-demo-break.yml` | Patch Service selector to `version=green` |
| `aks-demo-reset.yml` | Patch Service selector back to `version=blue` |
