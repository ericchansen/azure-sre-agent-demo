# Deploying Azure SRE Agent

This guide walks through deploying an Azure SRE Agent that monitors an existing application workload.

## What gets created

The Bicep templates in `bicep/` deploy the following resources into a dedicated resource group:

| Resource | Purpose |
|----------|---------|
| **Azure SRE Agent** (`Microsoft.App/agents`) | The AI agent that monitors, investigates, and remediates |
| **User-Assigned Managed Identity** | Identity the agent uses to access your monitored resources |
| **Application Insights** | Telemetry sink for the agent's own diagnostics |
| **Log Analytics Workspace** | Backing store for Application Insights |
| **Smart Detector Alert Rule** | Failure-anomaly detection on the agent's App Insights |
| **RBAC Role Assignments** | Reader + Contributor on both the agent RG and your target RG |

## Prerequisites

1. **Azure CLI** v2.60+ — [install](https://learn.microsoft.com/cli/azure/install-azure-cli)
2. **An Azure subscription** where you have `Owner` or `Contributor + User Access Administrator`
3. **A target resource group** containing the application you want the agent to monitor (the app must already be deployed)
4. **Azure SRE Agent preview access** — the `Microsoft.App/agents` resource type must be registered on your subscription

## Supported regions

Azure SRE Agent is available in:

- `eastus2`
- `swedencentral`
- `australiaeast`
- `uksouth`

> The agent can monitor resources in any region — it just needs to be *deployed* in a supported region.

## Step-by-step deployment

### 1. Log in and set your subscription

```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 2. Create the agent's resource group

```bash
az group create \
  --name rg-webstore-sre-agent \
  --location eastus2
```

### 3. Edit the parameters file

Copy `bicep/webstore-sre-agent.parameters.json` and replace the placeholder values:

| Parameter | What to set |
|-----------|-------------|
| `agentName` | A name for your agent (e.g., `webstore-sre-agent`) |
| `subscriptionId` | Your Azure subscription ID |
| `deploymentResourceGroupName` | The RG from step 2 |
| `location` | One of the supported regions above |
| `accessLevel` | `High` (can take actions) or `Low` (read-only investigation) |
| `targetResourceGroups` | Array of RG names the agent should monitor |
| `targetSubscriptions` | Array of subscription IDs where those RGs live |

### 4. Deploy

```bash
az deployment sub create \
  --location eastus2 \
  --template-file bicep/minimal-sre-agent.bicep \
  --parameters @bicep/webstore-sre-agent.parameters.json
```

The deployment takes 2–5 minutes. On success it outputs the agent name, portal URL, and identity details.

### 5. Verify in the portal

Open the portal URL from the deployment output. The agent will show `Building Knowledge Graph` initially — this is normal and takes a few minutes as it discovers your resources.

### 6. Connect GitHub source code (portal)

In the agent's portal blade:

1. Go to **Resource Mapping**
2. Add a mapping from your monitored Container App (or other resource) to the GitHub repository containing its source code
3. This lets the agent correlate telemetry anomalies back to specific code paths

### 7. Test with a healthy-state prompt

In the agent's chat interface, try:

```
What Azure resources can you see in rg-webstore-staging?
```

If the agent lists your resources, the knowledge graph and RBAC are working.

## Post-deployment: setting managed resources

> **Known quirk:** The official Bicep sample creates RBAC but leaves `knowledgeGraphConfiguration.managedResources` empty. You may need to patch this after deployment:

```bash
az resource update \
  --ids "/subscriptions/<SUB_ID>/resourceGroups/<AGENT_RG>/providers/Microsoft.App/agents/<AGENT_NAME>" \
  --set "properties.knowledgeGraphConfiguration.managedResources=['/subscriptions/<SUB_ID>/resourceGroups/<TARGET_RG>']" \
  --set "properties.logConfiguration.applicationInsightsConfiguration.appId=<APP_INSIGHTS_APP_ID>" \
  --set "properties.logConfiguration.applicationInsightsConfiguration.connectionString=<APP_INSIGHTS_CONN_STRING>"
```

Both `appId` and `connectionString` must be included on any update, even if you're only changing `managedResources`.

## File overview

| File | Description |
|------|-------------|
| `minimal-sre-agent.bicep` | Subscription-scoped entrypoint — creates the RG reference and calls the module |
| `sre-agent-resources.bicep` | Main module — agent, identity, App Insights, RBAC, alert rules |
| `role-assignments-minimal.bicep` | RBAC for the agent's own resource group |
| `role-assignments-target.bicep` | RBAC for the monitored target resource group |
| `webstore-sre-agent.parameters.json` | Example parameters (edit before deploying) |
