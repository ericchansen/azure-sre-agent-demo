# Azure SRE Agent Demo Hub

A collection of end-to-end, live-demo environments showing [Azure SRE Agent](https://sre.azure.com/docs/overview) detecting and remediating real application failures — automatically. Built for conference talks, internal show-and-tells, and hands-on workshops.

> 🌐 **[View the full documentation site →](https://ericchansen.github.io/azure-sre-agent-demo/)**

> **What is Azure SRE Agent?** An AI-powered site reliability agent that continuously monitors your Azure resources. When something breaks it [investigates telemetry](https://sre.azure.com/docs/capabilities/root-cause-analysis), [correlates it with source code](https://sre.azure.com/docs/concepts/workspace-tools), and [remediates](https://sre.azure.com/docs/capabilities/incident-response) — all without a human opening five tabs at 3 AM.
>
> 📖 **Official docs:** [sre.azure.com/docs](https://sre.azure.com/docs/)

---

## Scenarios

One SRE Agent instance (in `infra/sre-agent/`) monitors all demo resource groups. Each scenario is self-contained in its own directory under `scenarios/`.

| Scenario | Description | Workload | Key SRE Agent capabilities |
|----------|-------------|----------|---------------------------|
| **[Webstore: Container Apps](scenarios/webstore-container-apps/)** | Checkout API starts returning 503. Agent detects the spike, investigates App Insights traces, and rolls back the broken env var. | [Cacao & Co.](https://github.com/ericchansen/webstore) (Next.js on Azure Container Apps) | App Insights queries, GitHub code correlation, env var remediation |
| **[AKS: Blue/Green Deployment](scenarios/aks-blue-green/)** | A "green" deployment is rolled out with a broken build. Agent detects the error rate spike, rolls back the Kubernetes Service selector to blue, and creates a GitHub Issue. | Stub Node.js app on AKS | `kubectl` tooling, Container Insights, GitHub issue creation |

Want to add a scenario? See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Architecture

One SRE Agent (in `rg-webstore-sre-agent`, eastus2) monitors all demo resource groups. Its `targetResourceGroups` list grows as scenarios are added. Scenario-specific resources (app, monitoring alerts, runbooks) live under `scenarios/<name>/`.

```
┌──────────────────────────────────────────────────────┐
│  Azure SRE Agent  (eastus2)   rg-webstore-sre-agent  │
└──────────────────┬───────────────────────────────────┘
                   │  monitors all target RGs
         ┌─────────┴──────────┐
         ▼                    ▼
┌─────────────────┐   ┌─────────────────┐
│  rg-webstore-   │   │  rg-webstore-   │
│  demo           │   │  aks (planned)  │
│  (Container     │   │  (AKS cluster)  │
│   Apps, Webstore│   └─────────────────┘
└─────────────────┘        … more TBD
```

---

## Repositories

| Repo | What it contains |
|------|-----------------|
| **[azure-sre-agent-demo](https://github.com/ericchansen/azure-sre-agent-demo)** (this repo) | SRE Agent Bicep, scenario infra/runbooks/workflows, documentation hub |
| **[webstore](https://github.com/ericchansen/webstore)** | Next.js e-commerce app with built-in failure mode, OpenTelemetry instrumentation, Docker + Azure Container Apps deployment |

---

## Quick start

### Prerequisites

- Azure subscription with `Contributor` role ([+ `User Access Administrator` for RBAC](https://sre.azure.com/docs/get-started/create-and-setup#prerequisites))
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) v2.60+
- [GitHub CLI](https://cli.github.com/) (for workflow dispatch)

### 1. Deploy the SRE Agent

Follow the step-by-step guide in [`infra/sre-agent/README.md`](infra/sre-agent/README.md), or use the [portal wizard](https://sre.azure.com/docs/get-started/create-and-setup) at [sre.azure.com](https://sre.azure.com).

### 2. Set up a scenario

Each scenario's `README.md` has its own setup guide, required variables, and demo instructions:

- **[Webstore: Container Apps](scenarios/webstore-container-apps/README.md)**
- **[AKS: Blue/Green](scenarios/aks-blue-green/README.md)**

### 3. Run the demo

See each scenario's demo script, or the [**full documentation site**](https://ericchansen.github.io/azure-sre-agent-demo/).



---

## Demo workflows

Workflows are prefixed by scenario: `webstore-*`, `aks-*`, etc.

| Workflow | Scenario | What it does |
|----------|----------|-------------|
| 🔴 [`webstore-demo-break`](.github/workflows/webstore-demo-break.yml) | Webstore | Sets `DEMO_BROKEN_CHECKOUT=true`, polls until checkout returns 503 |
| 🟢 [`webstore-demo-reset`](.github/workflows/webstore-demo-reset.yml) | Webstore | Sets `DEMO_BROKEN_CHECKOUT=false`, polls until checkout returns 201 |
| 📊 [`webstore-deploy-monitoring`](.github/workflows/webstore-deploy-monitoring.yml) | Webstore | Deploys the failed-requests metric alert to the demo resource group |
| 🔴 [`aks-demo-break`](.github/workflows/aks-demo-break.yml) *(coming soon)* | AKS | Patches Service selector to green (broken) deployment |
| 🟢 [`aks-demo-reset`](.github/workflows/aks-demo-reset.yml) *(coming soon)* | AKS | Patches Service selector back to blue (stable) deployment |

```bash
# Webstore: break
gh workflow run "Webstore Demo: Break Checkout" -f environment=demo

# Webstore: reset
gh workflow run "Webstore Demo: Reset Checkout" -f environment=demo
```

---

## Repository structure

```
├── README.md                              ← you are here
├── CONTRIBUTING.md                        ← how to add a new scenario
├── docs-site/                             ← Docusaurus documentation site
├── infra/
│   └── sre-agent/                         ← shared SRE Agent Bicep (one agent for all)
│       ├── README.md
│       └── bicep/
│           ├── minimal-sre-agent.bicep
│           ├── sre-agent-resources.bicep
│           ├── role-assignments-minimal.bicep
│           ├── role-assignments-target.bicep
│           └── sre-agent.parameters.json  ← edit targetResourceGroups for your scenarios
├── scenarios/
│   ├── webstore-container-apps/           ← Scenario 1: webstore on Container Apps
│   │   ├── README.md
│   │   ├── infra/monitoring/              ← metric alert Bicep
│   │   └── runbooks/                      ← investigation runbooks
│   └── aks-blue-green/                    ← Scenario 2: AKS blue/green (coming soon)
│       ├── README.md
│       ├── app/                           ← stub Node.js app + Dockerfile
│       ├── infra/                         ← AKS cluster Bicep + alert
│       ├── k8s/                           ← blue/green Deployments + Service
│       └── runbooks/
└── .github/
    └── workflows/
        ├── webstore-demo-break.yml
        ├── webstore-demo-reset.yml
        ├── webstore-deploy-monitoring.yml
        ├── aks-demo-break.yml
        ├── aks-demo-reset.yml
        └── deploy-docs.yml
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
