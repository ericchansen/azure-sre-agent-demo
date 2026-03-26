---
sidebar_position: 1
title: Incident Response
description: How Azure SRE Agent detects, investigates, and remediates incidents.
---

# Incident Response

> This page summarizes the key concepts from the [official incident response docs](https://sre.azure.com/docs/capabilities/incident-response). Read those for the complete reference.

## The problem

When an alert fires at 3 AM, the on-call engineer has to:
1. Open the incident platform to see what's wrong
2. Switch to metrics dashboards
3. Open Log Analytics for errors
4. Check deployment history
5. Search Slack/Teams for context
6. Find a runbook that may be outdated

**Azure SRE Agent does all of this in seconds.**

## How it works

```
Alert fires
  → Agent acknowledges
  → Queries all connected data sources
  → Correlates logs + metrics + traces + deployments
  → Checks memory for similar past incidents
  → Forms hypotheses, validates with evidence
  → Proposes fix (Review) or executes immediately (Autonomous)
```

The agent doesn't follow a static script — it **reasons** about your specific situation, adapting its investigation based on what it finds.

## What makes it different

| | Runbooks | Dashboards | Scripts | SRE Agent |
|--|---------|-----------|---------|-----------|
| **Adapts?** | ❌ Static steps | ❌ Static views | ❌ Same steps every time | ✅ Reasons about context |
| **Learns?** | ❌ Goes stale | ❌ N/A | ❌ N/A | ✅ Persistent memory |
| **Acts?** | ❌ Manual steps | ❌ Just displays data | ✅ But blindly | ✅ With reasoning |
| **Correlates?** | ❌ Single source | ❌ Single source | ❌ Single source | ✅ All sources |

## In this demo

The SRE Agent detects the checkout failure via:
- **Application Insights** — spike in 503 responses on `POST /api/orders`
- **Span attributes** — error details, the `DEMO_BROKEN_CHECKOUT` flag value
- **Source code** — traces to `src/app/api/orders/route.ts` via Deep Context

The agent then proposes resetting the environment variable — or executes it automatically in Autonomous mode.

## Further reading

- [Incident Response — official docs](https://sre.azure.com/docs/capabilities/incident-response)
- [Incident Response Plans](https://sre.azure.com/docs/capabilities/incident-response-plans)
- [Root Cause Analysis](https://sre.azure.com/docs/capabilities/root-cause-analysis)
- [Deep Investigation](https://sre.azure.com/docs/capabilities/deep-investigation)
