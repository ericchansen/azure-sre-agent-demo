---
sidebar_position: 1
slug: /overview
title: Overview
description: What this demo is, what it shows, and how the pieces fit together.
---

# Overview

This repository contains everything you need to run a **live, end-to-end demo** of [Azure SRE Agent](https://sre.azure.com/docs/overview) detecting and remediating a real application failure — automatically.

:::tip Who is this for?
Conference speakers, technical evangelists, and anyone giving an **AIOps** or **Azure SRE Agent** demo. The failure and recovery are fully repeatable — run it as many times as you need.
:::

## What is Azure SRE Agent?

Azure SRE Agent is an AI-powered site reliability agent that continuously monitors your Azure resources. When something breaks, it:

- **Investigates** — correlates metrics, logs, traces, and deployment history ([root cause analysis](https://sre.azure.com/docs/capabilities/root-cause-analysis))
- **Understands code** — maps Azure resources back to GitHub source code via [Deep Context](https://sre.azure.com/docs/concepts/workspace-tools)
- **Remediates** — proposes or executes corrective actions depending on [run mode](https://sre.azure.com/docs/concepts/run-modes)
- **Remembers** — captures every investigation in [persistent memory](https://sre.azure.com/docs/concepts/memory) so it gets smarter over time

> 📖 **Official docs:** [sre.azure.com/docs](https://sre.azure.com/docs/)

## The demo story

A live e-commerce storefront — **[Cacao & Co.](https://github.com/ericchansen/webstore)** — runs on Azure Container Apps, fully instrumented with OpenTelemetry. An Azure SRE Agent monitors the environment.

| Step | What happens | Who does it |
|------|-------------|-------------|
| **1. Healthy baseline** | Visitors browse products, add to cart, check out. Telemetry flows to App Insights. | The app |
| **2. Break checkout** | A "bad deployment" sets `DEMO_BROKEN_CHECKOUT=true`. Checkout returns **503** with a 1.5 s delay. Rest of the site stays up. | You (one-click workflow) |
| **3. Detection** | SRE Agent sees the spike in 503 errors and failed dependency calls. | Azure SRE Agent |
| **4. Investigation** | The agent correlates logs, metrics, and traces. Maps the failure back to source code. | Azure SRE Agent |
| **5. Remediation** | Depending on run mode, the agent **recommends** or **executes** a fix. | Azure SRE Agent |
| **6. Recovery** | Checkout returns to 201. Telemetry confirms the fix. | The app |

## Repositories

| Repo | What it contains |
|------|-----------------|
| **[azure-sre-agent-demo](https://github.com/ericchansen/azure-sre-agent-demo)** | SRE Agent Bicep templates, demo workflows, this documentation |
| **[webstore](https://github.com/ericchansen/webstore)** | Next.js e-commerce app with built-in failure mode, OpenTelemetry, Docker + Container Apps deployment |

## Demo workflows

Two GitHub Actions workflows automate the break / fix cycle:

### 🔴 Demo: Break Checkout

1. Generates 30 baseline requests (healthy telemetry for contrast)
2. Sets `DEMO_BROKEN_CHECKOUT=true` on the Container App
3. Polls until checkout returns **503**

```bash
gh workflow run "Demo: Break Checkout" -f environment=staging
```

### 🟢 Demo: Reset Checkout

1. Sets `DEMO_BROKEN_CHECKOUT=false`
2. Polls until checkout returns **201**

```bash
gh workflow run "Demo: Reset Checkout" -f environment=staging
```

## Next steps

- **[Architecture](./architecture)** — how the pieces connect
- **[Getting Started](./getting-started)** — deploy the agent and configure workflows
- **[Demo Script](./demo-script)** — step-by-step presenter guide with speaker notes
