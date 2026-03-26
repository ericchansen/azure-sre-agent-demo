# Azure SRE Agent Demo

An end-to-end, live-demo environment showing [Azure SRE Agent](https://sre.azure.com/docs/overview) detecting and remediating a real application failure — automatically. Built for conference talks, internal show-and-tells, and hands-on workshops.

> 🌐 **[View the full documentation site →](https://ericchansen.github.io/azure-sre-agent-demo/)**

> **What is Azure SRE Agent?** An AI-powered site reliability agent that continuously monitors your Azure resources. When something breaks it [investigates telemetry](https://sre.azure.com/docs/capabilities/root-cause-analysis), [correlates it with source code](https://sre.azure.com/docs/concepts/workspace-tools), and [remediates](https://sre.azure.com/docs/capabilities/incident-response) — all without a human opening five tabs at 3 AM.
>
> 📖 **Official docs:** [sre.azure.com/docs](https://sre.azure.com/docs/)

---

## The story

A live e-commerce storefront — **[Cacao & Co.](https://github.com/ericchansen/webstore)** — runs on Azure Container Apps, fully instrumented with OpenTelemetry. An Azure SRE Agent monitors the environment. During the demo:

| Step | What happens | Who does it |
|------|-------------|-------------|
| **1. Healthy baseline** | Visitors browse products, add to cart, and complete checkout. Telemetry flows to Application Insights. | The app |
| **2. Break checkout** | A "bad deployment" sets `DEMO_BROKEN_CHECKOUT=true`. The checkout API starts returning **503** with a 1.5 s delay while the rest of the site stays up. | You (one-click workflow) |
| **3. Detection** | SRE Agent sees the spike in 503 errors and failed dependency calls in Application Insights. | Azure SRE Agent |
| **4. Investigation** | The agent correlates logs, metrics, and traces. It maps the failure back to the source code via the [connected GitHub repo](https://sre.azure.com/docs/concepts/workspace-tools). | Azure SRE Agent |
| **5. Remediation** | Depending on [run mode](https://sre.azure.com/docs/concepts/run-modes), the agent either **recommends** or **executes** a fix (rollback the env var). | Azure SRE Agent |
| **6. Recovery** | Checkout returns to 201. Telemetry confirms the fix. | The app |

The failure and recovery are fully repeatable — run it as many times as you need.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Azure SRE Agent  (eastus2)                                     │
│  rg-webstore-sre-agent                                          │
│                                                                 │
│  ┌───────────────────────┐    ┌─────────────────────────────┐   │
│  │  SRE Agent            │    │  Application Insights       │   │
│  │  (Microsoft.App/      │    │  + Log Analytics Workspace  │   │
│  │   agents)             │    │                             │   │
│  └───────────┬───────────┘    └─────────────────────────────┘   │
│              │  monitors & investigates                          │
└──────────────┼──────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Webstore Application  (centralus)                              │
│  rg-webstore-staging                                            │
│                                                                 │
│  ┌───────────────┐  ┌────────────┐  ┌────────┐  ┌───────────┐  │
│  │ Container App │  │ PostgreSQL │  │  ACR   │  │ Key Vault │  │
│  │ (Next.js)     │  │ Flexible   │  │        │  │           │  │
│  └───────────────┘  └────────────┘  └────────┘  └───────────┘  │
│         │                                                       │
│  ┌──────┴────────────────────────────────────────────────────┐  │
│  │  OpenTelemetry  ──▶  Application Insights (telemetry)     │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

**Key telemetry flow:** The webstore sends requests, dependencies, and exceptions to Application Insights via the [Azure Monitor OpenTelemetry SDK](https://learn.microsoft.com/azure/azure-monitor/app/opentelemetry-enable). The SRE Agent queries that same App Insights instance to detect anomalies.

---

## Repositories

| Repo | What it contains |
|------|-----------------|
| **[azure-sre-agent-demo](https://github.com/ericchansen/azure-sre-agent-demo)** (this repo) | SRE Agent Bicep templates, demo workflows, documentation |
| **[webstore](https://github.com/ericchansen/webstore)** | Next.js e-commerce app with built-in failure mode, OpenTelemetry instrumentation, Docker + Azure Container Apps deployment |

---

## Quick start

### Prerequisites

- Azure subscription with `Contributor` role ([+ `User Access Administrator` for RBAC](https://sre.azure.com/docs/get-started/create-and-setup#prerequisites))
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) v2.60+
- [GitHub CLI](https://cli.github.com/) (for workflow dispatch)
- The [webstore](https://github.com/ericchansen/webstore) deployed to Azure Container Apps (see the webstore README)

### 1. Deploy the SRE Agent

Follow the step-by-step guide in [`infra/sre-agent/README.md`](infra/sre-agent/README.md), or use the [portal wizard](https://sre.azure.com/docs/get-started/create-and-setup) at [sre.azure.com](https://sre.azure.com).

### 2. Connect data sources

In the SRE Agent setup, connect:
- **Code** → the [webstore](https://github.com/ericchansen/webstore) GitHub repo ([docs](https://sre.azure.com/docs/get-started/create-and-setup#connect-your-code-repository))
- **Azure resources** → the `rg-webstore-staging` resource group ([docs](https://sre.azure.com/docs/get-started/create-and-setup#add-azure-resource-access))

### 3. Configure repo secrets & variables

This repo's GitHub Actions workflows need OIDC credentials for Azure:

**Secrets** (per environment):
| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID (federated credential) |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription containing the Container App |

**Variables** (per environment):
| Variable | Example |
|----------|---------|
| `CONTAINER_APP_NAME` | `ca-webstore-staging` |
| `RESOURCE_GROUP` | `rg-webstore-staging` |

### 4. Run the demo

See the [**Demo script**](docs/demo-script.md) for a step-by-step walkthrough — what to click, what to show, and what to say.

---

## Demo workflows

Two GitHub Actions workflows automate the break / fix cycle:

### 🔴 [Demo: Break Checkout](.github/workflows/demo-break.yml)

1. Generates 30 baseline requests (healthy signal for contrast)
2. Sets `DEMO_BROKEN_CHECKOUT=true` on the Container App
3. Polls until checkout returns **503**

```bash
gh workflow run "Demo: Break Checkout" -f environment=staging
```

### 🟢 [Demo: Reset Checkout](.github/workflows/demo-reset.yml)

1. Sets `DEMO_BROKEN_CHECKOUT=false`
2. Polls until checkout returns **201**

```bash
gh workflow run "Demo: Reset Checkout" -f environment=staging
```

---

## Repository structure

```
├── README.md                          ← you are here
├── docs/
│   └── demo-script.md                 ← step-by-step presenter guide
├── .github/
│   └── workflows/
│       ├── demo-break.yml             ← break checkout (workflow dispatch)
│       └── demo-reset.yml             ← reset checkout (workflow dispatch)
└── infra/
    └── sre-agent/
        ├── README.md                  ← Bicep deployment guide
        └── bicep/
            ├── minimal-sre-agent.bicep
            ├── sre-agent-resources.bicep
            ├── role-assignments-minimal.bicep
            ├── role-assignments-target.bicep
            └── webstore-sre-agent.parameters.json
```

---

## How Azure SRE Agent works (for presenters)

If you're presenting this demo and need to explain the product, here are the key concepts:

### Incident response flow

> Alert fires → Agent acknowledges → Gathers context (logs, metrics, traces, deploys) → Forms hypotheses → Validates each one → Resolves or escalates

The agent doesn't run a script — it **reasons** about your specific situation. Each investigation builds [persistent memory](https://sre.azure.com/docs/concepts/memory) that makes future investigations faster.

### Run modes

| Mode | Behavior | Best for |
|------|----------|----------|
| **Review** | Agent proposes an action, you approve/deny | Production, critical infra |
| **Autonomous** | Agent executes immediately, reports what it did | Non-prod, trusted recurring tasks |

Start with Review. Switch to Autonomous once you trust the patterns. ([docs](https://sre.azure.com/docs/concepts/run-modes))

### Connectors

The agent has **built-in access** to Azure Monitor, App Insights, Log Analytics, and Resource Graph. You can extend it with [connectors](https://sre.azure.com/docs/concepts/connectors) for GitHub, Teams, Outlook, Kusto, PagerDuty, ServiceNow, and any custom API via [MCP](https://sre.azure.com/docs/concepts/skills).

### What makes it different

| vs. Runbooks | vs. Dashboards | vs. Scripts |
|-------------|---------------|-------------|
| Runbooks go stale. The agent learns from every investigation and builds [persistent memory](https://sre.azure.com/docs/concepts/memory). | Dashboards surface data for *you* to interpret. The agent interprets, hypothesizes, and acts. | Scripts run the same steps regardless. The agent adapts to the specific situation. |

---

## Learn more

| Topic | Link |
|-------|------|
| **Azure SRE Agent overview** | [sre.azure.com/docs/overview](https://sre.azure.com/docs/overview) |
| **Create your first agent** | [sre.azure.com/docs/get-started/create-and-setup](https://sre.azure.com/docs/get-started/create-and-setup) |
| **Incident response** | [sre.azure.com/docs/capabilities/incident-response](https://sre.azure.com/docs/capabilities/incident-response) |
| **Root cause analysis** | [sre.azure.com/docs/capabilities/root-cause-analysis](https://sre.azure.com/docs/capabilities/root-cause-analysis) |
| **Run modes (Review vs Autonomous)** | [sre.azure.com/docs/concepts/run-modes](https://sre.azure.com/docs/concepts/run-modes) |
| **Connectors** | [sre.azure.com/docs/concepts/connectors](https://sre.azure.com/docs/concepts/connectors) |
| **Memory & knowledge** | [sre.azure.com/docs/concepts/memory](https://sre.azure.com/docs/concepts/memory) |
| **Deep context (code understanding)** | [sre.azure.com/docs/concepts/workspace-tools](https://sre.azure.com/docs/concepts/workspace-tools) |
| **Official Bicep samples** | [github.com/microsoft/sre-agent](https://github.com/microsoft/sre-agent) |

---

## License

[MIT](LICENSE)
