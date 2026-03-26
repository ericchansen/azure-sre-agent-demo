---
sidebar_position: 10
title: Reference
description: Quick links to official Azure SRE Agent documentation.
---

# Reference

## Official Azure SRE Agent docs

| Topic | Link |
|-------|------|
| **Product overview** | [sre.azure.com/docs/overview](https://sre.azure.com/docs/overview) |
| **Create your first agent** | [sre.azure.com/docs/get-started/create-and-setup](https://sre.azure.com/docs/get-started/create-and-setup) |
| **Team onboarding** | [sre.azure.com/docs/get-started/team-onboarding](https://sre.azure.com/docs/get-started/team-onboarding) |
| **Incident response** | [sre.azure.com/docs/capabilities/incident-response](https://sre.azure.com/docs/capabilities/incident-response) |
| **Incident response plans** | [sre.azure.com/docs/capabilities/incident-response-plans](https://sre.azure.com/docs/capabilities/incident-response-plans) |
| **Root cause analysis** | [sre.azure.com/docs/capabilities/root-cause-analysis](https://sre.azure.com/docs/capabilities/root-cause-analysis) |
| **Deep investigation** | [sre.azure.com/docs/capabilities/deep-investigation](https://sre.azure.com/docs/capabilities/deep-investigation) |
| **Run modes** | [sre.azure.com/docs/concepts/run-modes](https://sre.azure.com/docs/concepts/run-modes) |
| **Connectors** | [sre.azure.com/docs/concepts/connectors](https://sre.azure.com/docs/concepts/connectors) |
| **Skills / MCP** | [sre.azure.com/docs/concepts/skills](https://sre.azure.com/docs/concepts/skills) |
| **Subagents** | [sre.azure.com/docs/concepts/subagents](https://sre.azure.com/docs/concepts/subagents) |
| **Memory & knowledge** | [sre.azure.com/docs/concepts/memory](https://sre.azure.com/docs/concepts/memory) |
| **Deep context (code)** | [sre.azure.com/docs/concepts/workspace-tools](https://sre.azure.com/docs/concepts/workspace-tools) |
| **Permissions** | [sre.azure.com/docs/concepts/permissions](https://sre.azure.com/docs/concepts/permissions) |
| **User roles** | [sre.azure.com/docs/concepts/user-roles](https://sre.azure.com/docs/concepts/user-roles) |
| **Scheduled tasks** | [sre.azure.com/docs/capabilities/scheduled-tasks](https://sre.azure.com/docs/capabilities/scheduled-tasks) |
| **Plugin marketplace** | [sre.azure.com/docs/capabilities/plugin-marketplace](https://sre.azure.com/docs/capabilities/plugin-marketplace) |
| **Hooks (governance)** | [sre.azure.com/docs/tutorials/agent-config/agent-hooks](https://sre.azure.com/docs/tutorials/agent-config/agent-hooks) |

## Repositories

| Repo | Description |
|------|-------------|
| [ericchansen/azure-sre-agent-demo](https://github.com/ericchansen/azure-sre-agent-demo) | This repo — Bicep templates, demo workflows, documentation |
| [ericchansen/webstore](https://github.com/ericchansen/webstore) | Next.js e-commerce app (the target workload) |
| [microsoft/sre-agent](https://github.com/microsoft/sre-agent) | Official Bicep samples from Microsoft |

## Azure services used

| Service | Purpose |
|---------|---------|
| [Azure Container Apps](https://learn.microsoft.com/azure/container-apps/) | Hosts the webstore |
| [Azure Container Registry](https://learn.microsoft.com/azure/container-registry/) | Docker image storage |
| [Azure Database for PostgreSQL](https://learn.microsoft.com/azure/postgresql/) | Product catalog, carts, orders |
| [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/) | Secrets management |
| [Application Insights](https://learn.microsoft.com/azure/azure-monitor/app/app-insights-overview) | OpenTelemetry telemetry sink |
| [Azure Monitor](https://learn.microsoft.com/azure/azure-monitor/) | Metrics and alerting |
| [Azure SRE Agent](https://sre.azure.com/docs/) | AI-powered site reliability |
