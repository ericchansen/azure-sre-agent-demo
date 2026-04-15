---
sidebar_position: 5
title: "💬 Prompt Catalog"
description: What to ask the SRE Agent at every stage — from open-ended exploration to direct remediation.
---

# 💬 Prompt Catalog

Prompts follow a **specificity progression**: start open-ended to showcase the agent's autonomous reasoning, get more directed if you need to steer it, and use direct action prompts when you know the fix and need speed. The pattern is **open-ended → directed → specific → remediation → action**. Match your prompt style to how much time you have and how much agency you want to give the agent.

---

## 1. Open-Ended Exploration 🔍

Let the agent investigate freely. These prompts showcase its ability to reason about symptoms, correlate signals, and form hypotheses without hand-holding.

### "I'm seeing checkout failures on the AKS webstore. Can you investigate?"

:::tip Expect the agent to…
Query App Insights for failed requests, identify the `/checkout` endpoint as the failure point, check pod health and service configuration, and eventually discover the selector mismatch.
:::

### "Something is wrong with the webstore in rg-webstore-aks. What's happening?"

:::tip Expect the agent to…
Start broad — list resources in the resource group, check AKS cluster health, review recent alerts, then narrow down to the service-level issue.
:::

### "The Azure Monitor alert for failed requests just fired on appi-aks-webstore-demo. What can you find?"

:::tip Expect the agent to…
Pull the alert details, run KQL queries against App Insights to identify which endpoints are failing, correlate with deployment timelines, and trace the issue to the green deployment.
:::

:::info Presenter note
Open-ended prompts are the most impressive in demos — the agent walks through its reasoning step by step. Budget 3-5 minutes for the agent to complete its investigation.
:::

---

## 2. Directed Investigation 🎯

Point the agent at a specific area. Useful when the agent is exploring too broadly or you want to fast-track to the interesting part of the scenario.

### "Check the Kubernetes Service selector on webstore-svc — is traffic going to blue or green?"

:::tip Expect the agent to…
Run `kubectl get service webstore-svc -o yaml` and inspect the `spec.selector.version` field, reporting whether it reads `blue` or `green`.
:::

### "Look at the pod environment variables for the green deployment in rg-webstore-aks"

:::tip Expect the agent to…
Get pods with `version=green` label, then describe them or exec into one to list environment variables — discovering `DEMO_BROKEN_CHECKOUT=true`.
:::

### "Query App Insights for failed requests on /checkout in the last 30 minutes"

:::tip Expect the agent to…
Run a KQL query filtering `requests` by `name` containing `/checkout` and `success == false`, showing the spike in 503 errors since the green deployment went live.
:::

### "Compare the blue and green deployments — what's different about their configuration?"

:::tip Expect the agent to…
Diff the two deployments' pod specs, highlighting that the green deployment sets `DEMO_BROKEN_CHECKOUT=true` while blue does not.
:::

---

## 3. Specific Diagnostic 🔬

Ask for exact commands or queries. These prompts leave no ambiguity — the agent executes precisely what you ask.

### "Run `kubectl get service webstore-svc -o jsonpath='{.spec.selector}'` and tell me what you see"

:::tip Expect the agent to…
Execute the command verbatim and report the selector output, e.g., `{"app":"webstore","version":"green"}`.
:::

### "Execute this KQL query against appi-aks-webstore-demo:"

```kusto
requests
| where success == false
| summarize count() by resultCode, bin(timestamp, 5m)
```

:::tip Expect the agent to…
Run the query against the App Insights resource and return a time-bucketed table of failure counts by status code.
:::

### "Check if any pods have DEMO_BROKEN_CHECKOUT in their environment variables"

:::tip Expect the agent to…
List pods and inspect their env vars, confirming that green pods have `DEMO_BROKEN_CHECKOUT=true` set.
:::

---

## 4. Remediation 🔧

Guide the agent toward fixing the issue. These prompts describe the problem and desired outcome without dictating the exact command.

### "The service selector is pointing to green, which has a broken checkout configuration. Can you switch it back to blue?"

:::tip Expect the agent to…
Patch the `webstore-svc` service selector from `version: green` to `version: blue`, then verify traffic is flowing to healthy pods.
:::

### "Patch webstore-svc to route traffic to the blue deployment and verify checkout works"

:::tip Expect the agent to…
Apply the selector patch, wait for traffic to shift, then test `/checkout` to confirm 201 responses instead of 503s.
:::

### "Roll back the service to the last known-good configuration and confirm recovery"

:::tip Expect the agent to…
Determine that "last known-good" means the blue deployment, patch the selector accordingly, and run health checks to validate recovery.
:::

:::note
Remediation prompts are ideal for showing the agent's ability to plan a fix, execute it, and verify the result — the full incident-response loop.
:::

---

## 5. Direct Action ⚡

Tell the agent exactly what to do. Use these when time is tight or the agent is struggling.

### "Run: `kubectl patch service webstore-svc -p '{\"spec\":{\"selector\":{\"version\":\"blue\"}}}'`"

:::tip Expect the agent to…
Execute the patch command immediately and report the result.
:::

### "Execute this fix and verify: patch the service selector to version=blue, then curl /checkout to confirm 201"

:::tip Expect the agent to…
Run the patch, then hit the `/checkout` endpoint to confirm the fix — providing concrete evidence of recovery.
:::

:::info Presenter note
Direct action prompts are your safety net. If the demo is running long or the agent is looping, drop one of these to get to the resolution quickly.
:::

---

## 6. Health Checks ✅

Use these **before the demo** to verify the environment is ready, or during the demo to establish a baseline.

### "What Azure resources can you see in rg-webstore-aks?"

:::tip Expect the agent to…
List resources in the resource group — AKS cluster, App Insights, networking components — confirming the environment is provisioned.
:::

### "Is the AKS cluster healthy? Check node status and pod health"

:::tip Expect the agent to…
Run `kubectl get nodes` and `kubectl get pods` to verify the cluster is running and all workloads are scheduled.
:::

### "Run a quick checkout test against the webstore LoadBalancer IP"

:::tip Expect the agent to…
Get the service's external IP and curl `/checkout`, confirming whether the endpoint returns 201 (healthy) or 503 (broken — ready for the demo).
:::

---

## 7. Follow-Up & Q&A 💡

Good prompts for after the fix — great during live Q&A or to wrap up the demo with a strong finish.

### "Summarize what you found and what you did"

:::tip Expect the agent to…
Produce a concise incident summary: symptoms, root cause (service selector pointing to broken green deployment), remediation (patched selector back to blue), and verification steps.
:::

### "If this happened again at 2 AM, could you fix it without human approval?"

:::tip Expect the agent to…
Discuss autonomous remediation capabilities, approval gates, and how SRE agents can be configured for different levels of autonomy.
:::

### "What would you monitor to prevent this from happening again?"

:::tip Expect the agent to…
Suggest monitoring improvements — canary deployments, automated rollback on error-rate thresholds, pre-switch health checks on green before cutting traffic.
:::

### "Create a GitHub issue documenting this incident"

:::tip Expect the agent to…
Draft an incident report issue with timeline, root cause, remediation steps, and follow-up action items.
:::

---

## Tips for Presenters

:::note Pacing your demo
- **Start with open-ended prompts** (Section 1) to showcase the agent's autonomous reasoning — this is the most impressive part.
- **Use directed prompts** (Section 2) if the agent goes off track or the audience is getting restless.
- **Save direct action prompts** (Section 5) as a fallback if the agent is taking too long to reach the fix.
- **In time-constrained demos** (under 10 minutes), skip to Section 2 or 3 to get to the action faster.
:::

:::tip Prompt progression during a live demo
A typical demo flow:
1. Fire one open-ended prompt and let the agent investigate (~3 min)
2. If needed, steer with a directed prompt (~1 min)
3. Let the agent propose or execute remediation (~2 min)
4. Use a follow-up prompt to wrap up and summarize (~1 min)
:::
