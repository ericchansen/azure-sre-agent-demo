---
sidebar_position: 5
title: "💬 Prompt Catalog"
description: What to ask the SRE Agent at every stage — from open-ended exploration to direct remediation.
---

# Prompt Catalog

A curated set of prompts for driving the Azure SRE Agent through the webstore Container Apps scenario. Prompts are organized in a **progression** — from wide-open investigation to surgical remediation — so presenters can dial the agent's autonomy up or down depending on audience and time.

This scenario has **multiple failure modes** (broken checkout, database errors, missing routes, resource exhaustion), which makes the prompt catalog richer than a single-fault demo. The primary demo path uses the `DEMO_BROKEN_CHECKOUT` flag, but the catalog covers all of them.

| Stage | What you're doing | When to use |
|-------|------------------|-------------|
| 🔍 Open-Ended | Let the agent explore freely | Start of demo — showcases reasoning |
| 🎯 Directed | Point the agent at a specific area | If open-ended is too slow or veers off |
| 🔬 Specific | Ask for exact data | When you need a precise answer on screen |
| 🔧 Remediation | Ask the agent to fix it | Climax of the demo |
| ⚡ Direct Action | Give the agent the exact command | Safety net if the agent stalls |
| ✅ Health Checks | Pre-demo verification | Before you go on stage |
| 🧪 Advanced | Explore other failure modes | Longer sessions or deep-dive Q&A |
| 💡 Follow-Up | Wrap-up and forward-looking | Q&A and closing |

---

## 🔍 Open-Ended Exploration

Start here to let the agent showcase its full reasoning chain. These prompts give minimal direction — the agent decides what to query, what to correlate, and what to investigate.

> **"Customers are reporting checkout failures on the webstore. Can you investigate?"**

> **"The Failed Requests alert fired on appi-webstore-prod. What's going on?"**

> **"Something is wrong with the Cocoa & Co. webstore in rg-webstore-prod. Please investigate."**

:::tip What the agent typically does
With an open-ended prompt, the agent will:
1. Query **App Insights** for recent failed requests and exceptions
2. Identify the spike in 503s on `POST /api/orders`
3. Check the **Container App** status, revisions, and environment variables
4. Correlate timestamps with recent deployments or configuration changes
5. Trace to **source code** on GitHub to understand the failure path

This chain is the most impressive thing to show an audience — let it run.
:::

---

## 🎯 Directed Investigation

If the open-ended approach is taking too long or the audience needs to see a specific capability, steer the agent toward a subsystem.

> **"Check the Container App environment variables for ca-webstore-prod — are there any demo flags enabled?"**

> **"Look at the App Insights failure distribution by HTTP status code for the last hour."**

> **"Check if there were any recent Container App revision deployments that could have introduced the issue."**

> **"Query dependencies and exceptions in App Insights — are there Prisma or PostgreSQL errors?"**

> **"List the Container App revisions and their traffic weights."**

:::tip When to use directed prompts
Use these when:
- The agent's open-ended investigation is exploring an area you don't want to focus on
- You have limited demo time and need to skip straight to the relevant subsystem
- You want to demonstrate a specific agent capability (e.g., reading environment variables, querying KQL)
:::

---

## 🔬 Specific Diagnostic

These prompts ask for exact data points. Use them to get a crisp, on-screen answer or to demonstrate the agent's ability to run precise queries.

> **"Run this KQL against appi-webstore-prod:"**
> ```kusto
> requests
> | where success == false
> | summarize count() by resultCode, bin(timestamp, 5m)
> ```

> **"Check the value of DEMO_BROKEN_CHECKOUT on ca-webstore-prod."**

> **"Show me the exception types from App Insights — specifically any Prisma P2003 or P1008 errors."**

> **"Look at the source code in the webstore GitHub repo — what does `src/app/api/orders/route.ts` do when DEMO_BROKEN_CHECKOUT is true?"**

:::info Source code tracing
The last prompt is a strong differentiator. The agent reads the actual source file on GitHub, identifies the `DEMO_BROKEN_CHECKOUT` check in `src/app/api/orders/route.ts`, and explains the simulated `PaymentGatewayConnectionRefused` error. This connects telemetry to code — something no traditional monitoring tool does.
:::

---

## 🔧 Remediation

Once the root cause is identified, ask the agent to fix it. In **Review mode**, the agent proposes the action and waits for approval. In **Autonomous mode**, it acts immediately.

> **"DEMO_BROKEN_CHECKOUT is set to true on the Container App. Can you set it to false to restore checkout?"**

> **"Roll back to the previous Container App revision if the latest one caused the failures."**

> **"The checkout failures are caused by a feature flag. Please update the container app environment variable and verify checkout works again."**

:::note Review vs. Autonomous mode
In **Review mode**, the agent shows the proposed `az containerapp update` command and waits for Approve / Deny. This is the recommended mode for live demos — it gives you a natural pause to narrate what's happening.

In **Autonomous mode**, the agent executes immediately. Great for showing speed, but you lose the "approve" moment.
:::

---

## ⚡ Direct Action

Safety-net prompts. If the agent's investigation stalls or you're running short on time, give it the exact command.

> **"Run: `az containerapp update --name ca-webstore-prod --resource-group rg-webstore-prod --set-env-vars DEMO_BROKEN_CHECKOUT=false`"**

> **"Verify the fix: query App Insights for the last 5 minutes of requests on POST /api/orders and confirm success rate is back to normal."**

:::tip When to use direct action
These are your **emergency brake**. In a live demo, if the agent is stuck in a loop or exploring the wrong path, jump to a direct action prompt to get the demo back on track. The audience still sees the agent execute and verify — they just miss the discovery phase.
:::

---

## ✅ Health Checks

Run these **before the demo** to confirm everything is ready. They also work as warm-up prompts to show the agent's awareness of the environment.

> **"What Azure resources are in rg-webstore-prod?"**

> **"Is the webstore Container App running? Check its provisioning state and latest revision."**

> **"Can you verify the PostgreSQL database is accessible and the webstore health endpoint returns ok?"**

> **"Are there any active Azure Monitor alerts in rg-webstore-prod?"**

:::info Pre-demo double-check
The agent's answers here confirm that:
- The Container App is provisioned and serving traffic
- PostgreSQL is online and connected
- App Insights is receiving telemetry
- No alerts are firing (yet)

If any of these fail, fix the infrastructure before starting the demo.
:::

---

## 🧪 Advanced Scenarios

For longer sessions or technical deep-dives, explore failure modes beyond the primary `DEMO_BROKEN_CHECKOUT` demo.

### Missing routes (404s)

> **"I'm seeing 404 errors on several pages. Which routes are returning 404 and do they exist in the source code?"**

:::note What happens
The agent queries App Insights for 404 responses, identifies paths like `/about`, `/contact`, `/shipping`, and `/returns`, then checks the GitHub repo to confirm these routes were never implemented. This demonstrates the agent's ability to distinguish between broken features and missing features.
:::

### Database errors (Prisma)

> **"The checkout is failing with a Prisma P2003 foreign key error. What products are missing from the database?"**

:::note What happens
The agent examines App Insights exceptions, identifies Prisma error codes (P2003 foreign key constraint, P1008 timeout, P2025 record not found), and correlates them with the database schema and seed data. This shows the agent reasoning about data-layer issues, not just infrastructure.
:::

### Resource exhaustion

> **"Response times are degrading across all endpoints. Check the Container App's CPU and memory metrics."**

:::note What happens
The agent queries Azure Monitor metrics for CPU and memory utilization on the Container App, checks if replicas are scaling, and looks for 503s across all endpoints (not just checkout). This demonstrates infrastructure-level diagnosis.
:::

---

## 💡 Follow-Up & Q&A

Use these after the remediation to wrap up the demo or during Q&A.

> **"Summarize the incident — what failed, why, and how you fixed it."**

> **"Create a GitHub issue on the webstore repo documenting this investigation."**

> **"What would you recommend to prevent this class of failure in the future?"**

> **"If this happened during off-hours, could you resolve it autonomously?"**

:::tip Great for Q&A
The last two prompts are audience favorites. The prevention question lets the agent recommend guardrails (CI checks for feature flags, canary deployments, alert-driven auto-remediation). The autonomy question naturally transitions into a discussion about Review vs. Autonomous mode and trust boundaries.
:::

---

## Tips for Presenters

1. **Start with open-ended prompts** to let the agent showcase its full reasoning chain. The discovery phase is the most impressive part of the demo.

2. **The primary demo path (`DEMO_BROKEN_CHECKOUT`) is the most reliable** for live demos. The failure is deterministic, the fix is a single environment variable, and the recovery is immediate.

3. **For longer sessions, explore the advanced scenarios.** Prisma errors and 404s show the agent reasoning about application-layer and data-layer issues, not just infrastructure.

4. **The agent's ability to read source code on GitHub is a strong differentiator.** Prompt for it explicitly — *"Look at the source code"* or *"What does route.ts do when..."*. This connects telemetry to code in a way that resonates with developers.

5. **Save direct action prompts as a safety net.** If the agent's investigation stalls during a live demo, jump to a direct action prompt to keep the demo moving. The audience still sees the agent execute and verify.

6. **Match your prompt style to the audience.** Executives respond to open-ended prompts ("Customers are reporting..."). Engineers prefer specific diagnostic prompts ("Run this KQL..."). Mix both for a diverse audience.
