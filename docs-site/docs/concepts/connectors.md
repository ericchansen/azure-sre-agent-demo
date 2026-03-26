---
sidebar_position: 3
title: Connectors
description: How Azure SRE Agent connects to your data sources and tools.
---

# Connectors

Azure SRE Agent has **built-in access** to Azure services and can be extended with connectors for external tools.

> Full reference: [sre.azure.com/docs/concepts/connectors](https://sre.azure.com/docs/concepts/connectors)

## Built-in (no setup required)

These work out of the box through the agent's managed identity and Azure RBAC:

| Capability | What it provides |
|-----------|-----------------|
| **Application Insights** | Query telemetry, traces, exceptions |
| **Log Analytics** | Query Log Analytics workspaces |
| **Azure Monitor metrics** | List and query metrics, analyze trends |
| **Azure Resource Graph** | Discover and query any Azure resource across subscriptions |
| **ARM / Azure CLI** | Read and modify any Azure resource type |
| **AKS diagnostics** | Run kubectl, diagnose Kubernetes issues |

## Configurable connectors

| Connector | What it enables |
|-----------|----------------|
| **GitHub / Azure DevOps** | Source code exploration via [Deep Context](https://sre.azure.com/docs/concepts/workspace-tools) |
| **Microsoft Teams** | Post investigation updates, share thread links |
| **Outlook** | Send email notifications and reports |
| **Kusto / ADX** | Query Azure Data Explorer clusters |
| **MCP servers** | Connect **any** external API — PagerDuty, ServiceNow, Jira, Datadog, Slack, internal tools |

## In this demo

The demo uses:
- **Application Insights** (built-in) — the agent queries this to detect the 503 spike
- **Azure Resource Graph** (built-in) — the agent discovers Container App resources
- **GitHub** (configured) — the agent traces failures back to source code
- **ARM** (built-in) — the agent can update environment variables on the Container App

## MCP integrations

The [Model Context Protocol (MCP)](https://sre.azure.com/docs/concepts/skills) lets you connect the agent to any service with an API. Browse community-built skills in the [Plugin Marketplace](https://sre.azure.com/docs/capabilities/plugin-marketplace) or build your own.

## Further reading

- [Connectors — official docs](https://sre.azure.com/docs/concepts/connectors)
- [Skills / MCP](https://sre.azure.com/docs/concepts/skills)
- [Plugin Marketplace](https://sre.azure.com/docs/capabilities/plugin-marketplace)
- [Deep Context](https://sre.azure.com/docs/concepts/workspace-tools)
- [Memory & Knowledge](https://sre.azure.com/docs/concepts/memory)
