# Demo script — Azure SRE Agent

A step-by-step presenter guide for running the Azure SRE Agent demo live. Designed for a 15–20 minute slot, but can be shortened to 10 minutes by trimming the setup narration.

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
curl -s https://ca-webstore-staging.salmonstone-d627e874.centralus.azurecontainerapps.io/api/health | jq .
# Expected: { "status": "healthy", ... }

# Checkout is working (not left in broken state)
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://ca-webstore-staging.salmonstone-d627e874.centralus.azurecontainerapps.io/api/orders \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","firstName":"Test","lastName":"User","address":"123 Main","city":"Seattle","state":"WA","zip":"98101","items":[{"productId":"1","name":"Test","price":10,"quantity":1}],"subtotal":10,"shippingCost":0,"tax":0.80,"total":10.80}'
# Expected: 201
```

### SRE Agent

1. Open [sre.azure.com](https://sre.azure.com) and navigate to your agent
2. Confirm the agent is **Active** (not still "Building Knowledge Graph")
3. Confirm the **webstore** GitHub repo is connected under data sources
4. Confirm `rg-webstore-staging` is listed under Azure resources

### Browser tabs (pre-open)

| Tab | URL | Purpose |
|-----|-----|---------|
| 1 | Webstore storefront | Show the live app |
| 2 | [sre.azure.com](https://sre.azure.com) — Agent chat | Watch the agent investigate |
| 3 | Azure Portal — Application Insights (Live Metrics or Failures) | Show telemetry in real time |
| 4 | GitHub Actions — this repo | Trigger workflows |

### Optional: generate warm traffic

If the app has been idle, generate a few requests so App Insights has recent data:

```bash
for i in $(seq 1 5); do
  curl -s https://ca-webstore-staging.salmonstone-d627e874.centralus.azurecontainerapps.io/api/health > /dev/null
  curl -s https://ca-webstore-staging.salmonstone-d627e874.centralus.azurecontainerapps.io/products > /dev/null
done
```

---

## Part 1: Set the scene (3 min)

### Show the app

1. Switch to the **webstore storefront** tab
2. Browse a few products, add one to the cart, open the cart
3. Complete a checkout — show the success confirmation

> **Say:** "This is a real e-commerce app running on Azure Container Apps. It's a Next.js storefront backed by PostgreSQL, fully instrumented with OpenTelemetry. Every request, every dependency call, every exception flows to Application Insights."

### Show the telemetry

1. Switch to **Application Insights → Live Metrics** (or the Failures blade)
2. Point out healthy request rates, zero failures

> **Say:** "Right now everything is green. The SRE Agent is quietly monitoring this environment — it has access to these metrics, the logs, and the source code repo on GitHub."

### Show the SRE Agent

1. Switch to the **SRE Agent** tab at [sre.azure.com](https://sre.azure.com)
2. Show the agent dashboard — connected resources, connected code repo
3. Optionally ask: *"What Azure resources can you see in rg-webstore-staging?"*

> **Say:** "This is Azure SRE Agent. It's connected to our Application Insights, our resource group, and the GitHub repo that contains the webstore source code. It's running in Review mode — it will investigate autonomously but propose actions for approval before executing them."

---

## Part 2: Break it (2 min)

### Trigger the failure

1. Switch to **GitHub Actions** tab
2. Navigate to **"Demo: Break Checkout"** workflow
3. Click **Run workflow** → select **staging** → click **Run workflow**

> **Say:** "I'm simulating a bad deployment. All this does is flip one environment variable — `DEMO_BROKEN_CHECKOUT=true` — on the Container App. The app's checkout endpoint will start returning 503 errors with a simulated timeout, while the rest of the site stays up."

### Confirm the break

1. Wait for the workflow to complete (~1 min) — it generates baseline traffic first, then breaks checkout, then polls until it sees 503
2. Switch to the **storefront** — try to check out, show the error
3. Switch to **App Insights** — watch the 503s appear in real time

> **Say:** "Checkout is down. Products still load, the cart works, but the moment you try to place an order — 503. If this were a script or a simple health check, we'd know *something* is wrong. But the SRE Agent is about to tell us *what* is wrong and *how to fix it*."

---

## Part 3: Watch the agent work (5–10 min)

### The investigation

1. Switch to the **SRE Agent** tab
2. The agent should start investigating the spike in errors automatically (if configured with an [incident response plan](https://sre.azure.com/docs/capabilities/incident-response-plans)), or you can prompt it:

> *"I'm seeing checkout failures on the webstore Container App. Can you investigate?"*

3. Watch the agent's reasoning chain:
   - Queries Application Insights for recent exceptions and failed requests
   - Notices the spike in 503 responses on `POST /api/orders`
   - Examines the span attributes and exception details
   - Correlates with recent changes (environment variable update)
   - Traces to the source code — identifies the `DEMO_BROKEN_CHECKOUT` flag in `src/app/api/orders/route.ts`

> **Say:** "Watch what's happening. The agent is querying App Insights, looking at the traces, and forming hypotheses. It's not following a runbook — it's *reasoning* about what's different. And because it has access to the GitHub repo, it can trace the telemetry all the way back to the line of code that's causing this."

### The recommendation

4. The agent proposes a remediation — likely resetting the `DEMO_BROKEN_CHECKOUT` env var to `false`
5. In **Review mode**, it shows an Approve/Deny prompt

> **Say:** "The agent found the root cause and is proposing a specific fix. In Review mode, I get to approve or deny. In Autonomous mode, it would have already done this — the checkout would have been restored before anyone even noticed."

### Approve (or skip to manual reset)

6. If the agent's proposal is actionable — **Approve** it
7. If the demo needs a faster turnaround, manually reset:

```bash
gh workflow run "Demo: Reset Checkout" -f environment=staging
```

---

## Part 4: Recovery (2 min)

1. Wait for checkout to come back (~30 s after the env var flip)
2. Switch to the **storefront** — complete a checkout, show success
3. Switch to **App Insights** — show the 503s stopping, 201s resuming

> **Say:** "We're back. Zero downtime for browsing, and checkout was restored in under two minutes. The agent captured the full investigation in its memory — so next time it sees this pattern, it'll resolve it even faster."

---

## Key talking points

Use these throughout the demo or in Q&A:

### "How is this different from just setting up an alert?"

> "An alert tells you *something* is wrong. The SRE Agent tells you *what* is wrong, *why* it happened, and *how to fix it*. It correlates across metrics, logs, traces, deployments, and source code — the same investigation that would take an on-call engineer 15–30 minutes happens in seconds."

### "What if I don't trust it to take action?"

> "Start in [Review mode](https://sre.azure.com/docs/concepts/run-modes). The agent investigates autonomously but proposes actions for your approval before executing anything on Azure infrastructure. Once you see patterns you're always approving, switch those specific triggers to Autonomous."

### "Does it only work with Container Apps?"

> "No — it works with any Azure resource accessible via ARM. App Services, AKS, VMs, Functions, databases, networking — anything in your resource group. It also extends to external tools via [connectors](https://sre.azure.com/docs/concepts/connectors) and [MCP integrations](https://sre.azure.com/docs/concepts/skills)."

### "Does it remember past incidents?"

> "Yes. Every investigation gets captured in the agent's [persistent memory](https://sre.azure.com/docs/concepts/memory). The next time a similar issue appears, it references what worked before. Your team's institutional knowledge compounds instead of walking out the door."

### "How do I get started?"

> "Go to [sre.azure.com](https://sre.azure.com), sign in, and the wizard walks you through creating an agent in about 5 minutes. Connect your Azure resources and a code repo, and you're up and running. It starts learning your environment immediately."

---

## Cleanup

After the demo, make sure checkout is restored:

```bash
gh workflow run "Demo: Reset Checkout" -f environment=staging
```

Verify:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  -X POST https://ca-webstore-staging.salmonstone-d627e874.centralus.azurecontainerapps.io/api/orders \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","firstName":"Test","lastName":"User","address":"123 Main","city":"Seattle","state":"WA","zip":"98101","items":[{"productId":"1","name":"Test","price":10,"quantity":1}],"subtotal":10,"shippingCost":0,"tax":0.80,"total":10.80}'
# Expected: 201
```

---

## Timing guide

| Section | Duration | Notes |
|---------|----------|-------|
| Set the scene | 3 min | Show app, telemetry, agent |
| Break it | 2 min | Trigger workflow, confirm 503 |
| Agent investigates | 5–10 min | This varies — the agent may take a few minutes |
| Recovery | 2 min | Show restoration |
| Q&A | 5 min | Use the talking points above |
| **Total** | **15–20 min** | Can compress to 10 min by prompting the agent directly |

---

## Further reading

- [Azure SRE Agent overview](https://sre.azure.com/docs/overview)
- [Incident response capabilities](https://sre.azure.com/docs/capabilities/incident-response)
- [Root cause analysis](https://sre.azure.com/docs/capabilities/root-cause-analysis)
- [Run modes (Review vs Autonomous)](https://sre.azure.com/docs/concepts/run-modes)
- [Connectors & integrations](https://sre.azure.com/docs/concepts/connectors)
- [Memory & knowledge](https://sre.azure.com/docs/concepts/memory)
- [Webstore source code](https://github.com/ericchansen/webstore)
