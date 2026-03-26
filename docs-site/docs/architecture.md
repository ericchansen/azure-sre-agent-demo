---
sidebar_position: 2
title: Architecture
description: How the webstore, Azure SRE Agent, and Application Insights connect.
---

# Architecture

## System diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Azure SRE Agent  (eastus2)                                     │
│  rg-webstore-sre-agent                                          │
│                                                                 │
│  ┌───────────────────────┐    ┌─────────────────────────────┐   │
│  │  SRE Agent            │    │  Application Insights       │   │
│  │  (Microsoft.App/      │    │  + Log Analytics Workspace  │   │
│  │   agents)             │    │                             │   │
│  └───────────┬───────────┘    └──────────────┬──────────────┘   │
│              │  monitors & investigates       │                  │
└──────────────┼───────────────────────────────┼──────────────────┘
               │                               │
               ▼                               │ telemetry
┌──────────────────────────────────────────────┼──────────────────┐
│  Webstore Application  (centralus)           │                  │
│  rg-webstore-staging                         │                  │
│                                              │                  │
│  ┌───────────────┐  ┌────────────┐  ┌────────┴──┐ ┌──────────┐ │
│  │ Container App │  │ PostgreSQL │  │ App       │ │ Key Vault│ │
│  │ (Next.js +    │  │ Flexible   │  │ Insights  │ │          │ │
│  │  OpenTelemetry│──│ Server     │  │ (telemetry│ │          │ │
│  │  SDK)         │  │            │  │  sink)    │ │          │ │
│  └───────────────┘  └────────────┘  └───────────┘ └──────────┘ │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Azure Container Registry (ACR)                           │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Telemetry flow

The webstore uses the [Azure Monitor OpenTelemetry SDK](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable) to instrument every request:

1. **Container App** runs Next.js with a [preload script](https://github.com/ericchansen/webstore/blob/master/telemetry-preload.js) that initializes OpenTelemetry before the app starts
2. Every HTTP request, database query, and exception becomes a **span** in Application Insights
3. The checkout API (`POST /api/orders`) adds custom span attributes — order details, error codes, the `DEMO_BROKEN_CHECKOUT` flag
4. **Azure SRE Agent** queries Application Insights to detect anomalies and correlate failures

:::info Why a preload script?
Next.js standalone mode's file tracing can't follow dynamic imports in `instrumentation.ts`. The preload script (`node --require ./telemetry-preload.js server.js`) bypasses the Next.js instrumentation hook entirely and ensures OpenTelemetry is initialized before any application code runs.
:::

## The failure mechanism

When `DEMO_BROKEN_CHECKOUT=true` is set on the Container App:

| Aspect | Behavior |
|--------|----------|
| **Browsing** | ✅ Works normally — product listing, detail pages, cart |
| **Health check** | ✅ Always returns 200 (decoupled from business logic) |
| **Checkout** | ❌ Returns **503** after a 1.5 s simulated delay |
| **Telemetry** | Records error attributes, exception events, and 503 status on the span |

This creates a realistic "partial outage" scenario — exactly the kind of subtle failure that traditional health checks miss but an SRE Agent can detect through telemetry correlation.

## Resource groups

| Resource Group | Region | Contains |
|----------------|--------|----------|
| `rg-webstore-staging` | centralus | Container App, PostgreSQL, ACR, Key Vault, App Insights (telemetry) |
| `rg-webstore-sre-agent` | eastus2 | SRE Agent, App Insights (agent diagnostics), Log Analytics, Managed Identity |

:::note Why different regions?
Azure SRE Agent is available in [specific regions](https://sre.azure.com/docs/get-started/create-and-setup) (eastus2, swedencentral, australiaeast, uksouth). The agent can monitor resources in **any** region — it just needs to be deployed in a supported one.
:::

## CI/CD

| Workflow | Repo | Purpose |
|----------|------|---------|
| `demo-break.yml` | azure-sre-agent-demo | Break checkout (workflow dispatch) |
| `demo-reset.yml` | azure-sre-agent-demo | Restore checkout (workflow dispatch) |
| `ci.yml` | webstore | Lint, typecheck, test on every push/PR |
| `deploy.yml` | webstore | Build Docker image, push to ACR, update Container App |
| `pr-staging.yml` | webstore | Ephemeral staging environments for PRs |
