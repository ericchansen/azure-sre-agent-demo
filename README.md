# Azure SRE Agent Demo

End-to-end demo of [Azure SRE Agent](https://learn.microsoft.com/azure/sre-agent/overview) detecting and remediating a real application failure — automatically.

## What is Azure SRE Agent?

Azure SRE Agent is an AI-powered site reliability agent (currently in preview) that continuously monitors your Azure resources. When something goes wrong it can:

- **Investigate** — correlate metrics, logs, and traces to pinpoint the root cause
- **Understand code** — map Azure resources back to GitHub source code to find the offending change
- **Remediate** — take bounded corrective actions (rollback a deployment, scale a resource, restart a service)

## What this demo shows

A live e-commerce storefront ("Webstore") running on Azure Container Apps is monitored by a dedicated SRE Agent. During the demo:

1. The storefront is healthy — browsing, cart, and checkout all work
2. A bad deployment breaks the checkout API while the rest of the site stays up
3. Azure SRE Agent detects the spike in order failures, investigates the telemetry, traces it back to the source change, and recommends (or executes) a rollback
4. The storefront recovers — all without human intervention

The failure and recovery are fully repeatable for live demos.

## Repository structure

```
├── README.md
├── LICENSE
└── infra/
    └── sre-agent/
        ├── README.md                              ← deployment guide
        └── bicep/
            ├── minimal-sre-agent.bicep            ← subscription-scoped entrypoint
            ├── sre-agent-resources.bicep           ← agent, identity, App Insights, RBAC
            ├── role-assignments-minimal.bicep      ← RBAC for the agent's own resource group
            ├── role-assignments-target.bicep       ← RBAC for the monitored resource group
            └── webstore-sre-agent.parameters.json  ← example parameter values
```

## Getting started

See [`infra/sre-agent/README.md`](infra/sre-agent/README.md) for step-by-step deployment instructions.

### Prerequisites

- An Azure subscription with `Owner` or `Contributor + User Access Administrator` role
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) v2.60+
- An application workload already running in Azure (this demo uses a Next.js storefront on Container Apps)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Azure SRE Agent (eastus2)                              │
│  rg-webstore-sre-agent                                  │
│  ┌───────────────────┐  ┌────────────────────────────┐  │
│  │  SRE Agent        │  │  App Insights              │  │
│  │  (Microsoft.App/  │  │  + Log Analytics           │  │
│  │   agents)         │  │                            │  │
│  └───────┬───────────┘  └────────────────────────────┘  │
│          │ monitors                                     │
└──────────┼──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│  Webstore Application                                   │
│  rg-webstore-staging                                    │
│  ┌──────────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐  │
│  │ Container App│ │ Postgres │ │  ACR    │ │Key Vault│  │
│  └──────────────┘ └──────────┘ └─────────┘ └────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Related resources

- [Azure SRE Agent documentation](https://learn.microsoft.com/azure/sre-agent/overview)
- [Azure SRE Agent quickstart](https://learn.microsoft.com/azure/sre-agent/quickstart)
- [microsoft/sre-agent (official Bicep samples)](https://github.com/microsoft/sre-agent)

## License

[MIT](LICENSE)
