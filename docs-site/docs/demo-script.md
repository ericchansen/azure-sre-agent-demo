---
sidebar_position: 4
title: "🎤 Demo Script"
description: Step-by-step presenter guide with speaker notes, timing, and talking points.
---

# Demo Script

A step-by-step presenter guide for running the Azure SRE Agent demo live. Designed for a **15–20 minute** slot, but can be shortened to 10 minutes by trimming the setup narration.

---

## Before the demo

Run through this checklist **the morning of** your presentation.

### Infrastructure health

```bash
# PostgreSQL is running
az postgres flexible-server show \
  --name psql-webstore-staging \
  --resource-group rg-webstore-staging \
  --query "state" -o tsv
# Expected: "Ready"

# Container App is responding
curl -s https://<YOUR_APP_FQDN>/api/health | jq .
# Expected: { "status": "healthy", ... }

# Checkout is NOT left in broken state
curl -s -o /dev/null -w "%{http_code}" \
  -X POST "https://<YOUR_APP_FQDN>/api/orders" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","firstName":"Test","lastName":"User","address":"123 Main","city":"Seattle","state":"WA","zip":"98101","items":[{"productId":"1","name":"Test","price":10,"quantity":1}],"subtotal":10,"shippingCost":0,"tax":0.80,"total":10.80}'
# Expected: 201
```

### SRE Agent

1. Open [sre.azure.com](https://sre.azure.com) and navigate to your agent
2. Confirm the agent is **Active** (not "Building Knowledge Graph")
3. Confirm the **webstore** GitHub repo is connected under data sources
4. Confirm `rg-webstore-staging` is listed under Azure resources

### Browser tabs (pre-open)

| Tab | What to open | Purpose |
|-----|-------------|---------|
| 1 | Webstore storefront | Show the live app |
| 2 | [sre.azure.com](https://sre.azure.com) — Agent chat | Watch the agent investigate |
| 3 | Azure Portal — App Insights (Live Metrics or Failures) | Real-time telemetry |
| 4 | GitHub Actions — this repo | Trigger workflows |

---

## Part 1: Set the scene {#scene}

**⏱️ ~3 minutes**

### Show the app

1. Switch to the **webstore** tab
2. Browse a few products, add one to the cart
3. Complete a checkout — show the success confirmation

:::tip Speaker notes
> "This is a real e-commerce app running on Azure Container Apps. It's a Next.js storefront backed by PostgreSQL, fully instrumented with OpenTelemetry. Every request, every dependency call, every exception flows to Application Insights."
:::

### Show the telemetry

1. Switch to **Application Insights → Live Metrics** (or the Failures blade)
2. Point out healthy request rates, zero failures

:::tip Speaker notes
> "Right now everything is green. The SRE Agent is quietly monitoring this environment — it has access to these metrics, the logs, and the source code repo on GitHub."
:::

### Show the SRE Agent

1. Switch to [sre.azure.com](https://sre.azure.com)
2. Show the agent dashboard — connected resources, connected code repo
3. Optionally ask: *"What Azure resources can you see in rg-webstore-staging?"*

:::tip Speaker notes
> "This is Azure SRE Agent. It's connected to our Application Insights, our resource group, and the GitHub repo with the webstore source code. It's running in Review mode — it'll investigate autonomously but ask before taking action."
:::

---

## Part 2: Break it {#break}

**⏱️ ~2 minutes**

### Trigger the failure

1. Switch to **GitHub Actions**
2. Navigate to **"Demo: Break Checkout"**
3. Click **Run workflow** → select **staging** → click **Run workflow**

:::tip Speaker notes
> "I'm simulating a bad deployment. All this does is flip one environment variable — `DEMO_BROKEN_CHECKOUT=true`. The checkout API will start returning 503 with a simulated timeout, while the rest of the site stays perfectly healthy."
:::

### Confirm the break

1. Wait for the workflow to complete (~1 min)
2. Switch to the **storefront** — try to check out, show the error
3. Switch to **App Insights** — watch the 503s appear

:::tip Speaker notes
> "Checkout is down. Products still load, the cart works, but placing an order gives a 503. If this were a simple health check, it would still say 'healthy.' But the SRE Agent is about to tell us *what* is wrong and *how to fix it*."
:::

---

## Part 3: Watch the agent {#investigate}

**⏱️ ~5–10 minutes**

### The investigation

1. Switch to the **SRE Agent** tab
2. The agent may start investigating automatically (if you've set up an [incident response plan](https://sre.azure.com/docs/capabilities/incident-response-plans)), or prompt it:

> *"I'm seeing checkout failures on the webstore Container App in rg-webstore-staging. Can you investigate?"*

3. Watch the reasoning chain:
   - Queries App Insights for recent exceptions and failed requests
   - Notices the spike in 503s on `POST /api/orders`
   - Examines span attributes and exception details
   - Correlates with recent environment variable changes
   - Traces to source code — identifies the `DEMO_BROKEN_CHECKOUT` flag

:::tip Speaker notes
> "Watch what's happening. The agent is querying App Insights, looking at traces, and forming hypotheses. It's not following a runbook — it's *reasoning* about what's different. And because it has access to the GitHub repo, it can trace the telemetry all the way back to the line of code."
:::

### The recommendation

4. The agent proposes a remediation — resetting `DEMO_BROKEN_CHECKOUT` to `false`
5. In **Review mode**, it shows Approve / Deny

:::tip Speaker notes
> "The agent found the root cause and is proposing a specific fix. In Review mode, I approve or deny. In Autonomous mode, it would have already done this — checkout restored before anyone noticed."
:::

### Approve (or manual reset)

6. **Approve** the agent's proposal if actionable, or:

```bash
gh workflow run "Demo: Reset Checkout" -f environment=staging
```

---

## Part 4: Recovery {#recovery}

**⏱️ ~2 minutes**

1. Wait ~30 s after the env var flips
2. Switch to **storefront** — complete a checkout, show success
3. Switch to **App Insights** — 503s stop, 201s resume

:::tip Speaker notes
> "We're back. Zero downtime for browsing, and checkout was restored in under two minutes. The agent captured the full investigation in its memory — next time it sees this pattern, it'll resolve it even faster."
:::

---

## Key talking points {#talking-points}

Use these throughout the demo or in Q&A:

### "How is this different from just an alert?"

> An alert tells you *something* is wrong. The SRE Agent tells you *what* is wrong, *why* it happened, and *how to fix it*. It correlates across metrics, logs, traces, deployments, and source code — the same investigation that takes an on-call engineer 15–30 minutes happens in seconds.

### "What if I don't trust it to act?"

> Start in [Review mode](https://sre.azure.com/docs/concepts/run-modes). The agent investigates autonomously but proposes actions for your approval. Once you see patterns you're always approving, switch those to Autonomous.

### "Does it only work with Container Apps?"

> No — it works with any Azure resource accessible via ARM. App Services, AKS, VMs, Functions, databases, networking. Plus external tools via [connectors](https://sre.azure.com/docs/concepts/connectors) and [MCP](https://sre.azure.com/docs/concepts/skills).

### "Does it remember past incidents?"

> Yes. Every investigation gets captured in [persistent memory](https://sre.azure.com/docs/concepts/memory). Institutional knowledge compounds instead of walking out the door.

### "How do I get started?"

> Go to [sre.azure.com](https://sre.azure.com), sign in, and the wizard walks you through creating an agent in about 5 minutes. Connect your Azure resources and a code repo, and you're up and running.

---

## Timing guide

| Section | Duration | Notes |
|---------|----------|-------|
| Set the scene | 3 min | Show app, telemetry, agent |
| Break it | 2 min | Trigger workflow, confirm 503 |
| Agent investigates | 5–10 min | Varies based on agent response time |
| Recovery | 2 min | Show restoration |
| Q&A | 5 min | Use the talking points above |
| **Total** | **15–20 min** | Compress to 10 min by prompting the agent directly |

---

## Cleanup

After the demo, make sure checkout is restored:

```bash
gh workflow run "Demo: Reset Checkout" -f environment=staging
```
