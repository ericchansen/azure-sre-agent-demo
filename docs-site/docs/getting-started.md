---
sidebar_position: 3
title: Getting Started
description: Deploy the agent, connect data sources, configure workflows.
---

# Getting Started

## Prerequisites

- Azure subscription with `Contributor` role ([+ User Access Admin for RBAC](https://sre.azure.com/docs/get-started/create-and-setup#prerequisites))
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) v2.60+ and [GitHub CLI](https://cli.github.com/)
- The [webstore](https://github.com/ericchansen/webstore) deployed to Azure Container Apps with telemetry flowing

## 1. Deploy the SRE Agent

**Portal (recommended):** Go to [sre.azure.com](https://sre.azure.com) → sign in → follow the 3-step wizard ([walkthrough](https://sre.azure.com/docs/get-started/create-and-setup)).

**Bicep:** See [`infra/sre-agent/README.md`](https://github.com/ericchansen/azure-sre-agent-demo/blob/main/infra/sre-agent/README.md) for the template-based approach.

:::caution Supported regions
Azure SRE Agent deploys to: `eastus2`, `swedencentral`, `australiaeast`, `uksouth`. It can monitor resources in any region.
:::

## 2. Connect data sources

After deployment, on the agent setup page:

1. **Code** → click **+** → GitHub → select the [webstore](https://github.com/ericchansen/webstore) repo ([docs](https://sre.azure.com/docs/get-started/create-and-setup#connect-your-code-repository))
2. **Azure resources** → Full setup tab → **+** → Resource groups → select `rg-webstore-staging` ([docs](https://sre.azure.com/docs/get-started/create-and-setup#add-azure-resource-access))

Verify in the agent chat: *"What Azure resources can you see in rg-webstore-staging?"*

## 3. Configure workflow secrets

The demo workflows use [OIDC](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure) to authenticate. In **Settings → Environments → staging**:

| Secrets | Variables |
|---------|-----------|
| `AZURE_CLIENT_ID` — app registration client ID | `CONTAINER_APP_NAME` — e.g. `ca-webstore-staging` |
| `AZURE_TENANT_ID` — Entra ID tenant | `RESOURCE_GROUP` — e.g. `rg-webstore-staging` |
| `AZURE_SUBSCRIPTION_ID` — target subscription | |

## 4. Test

```bash
gh workflow run "Demo: Break Checkout" -f environment=staging
gh run watch
gh workflow run "Demo: Reset Checkout" -f environment=staging
```
