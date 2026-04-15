# SRE Agent Configuration Scripts

Push scenario-specific SRE Agent definitions (custom agents, data connectors, and knowledge base documents) to an Azure SRE Agent dataplane v2 endpoint.

## Prerequisites

| Requirement | Details |
|---|---|
| **PowerShell** | PowerShell 7+ (`pwsh`) is required to run `Configure-SreAgent.ps1` |
| **Azure CLI** | Authenticated — run `az login` before use |
| **powershell-yaml** | `Install-Module powershell-yaml -Scope CurrentUser` |
| **SRE Agent endpoint** | The base URL of your deployed SRE Agent instance |

## Usage

Run the script with PowerShell 7+ using `pwsh`:

```powershell
# Configure the AKS blue-green scenario
pwsh ./scripts/Configure-SreAgent.ps1 `
  -ScenarioPath ./scenarios/aks-blue-green `
  -AgentEndpoint https://your-agent.sre.azure.com

# Configure the webstore Container Apps scenario
./scripts/Configure-SreAgent.ps1 `
  -ScenarioPath ./scenarios/webstore-container-apps `
  -AgentEndpoint https://your-agent.sre.azure.com

# Dry run — preview what would be configured without making API calls
./scripts/Configure-SreAgent.ps1 `
  -ScenarioPath ./scenarios/aks-blue-green `
  -AgentEndpoint https://your-agent.sre.azure.com `
  -DryRun

# Verbose output for debugging
./scripts/Configure-SreAgent.ps1 `
  -ScenarioPath ./scenarios/aks-blue-green `
  -AgentEndpoint https://your-agent.sre.azure.com `
  -Verbose
```

## SRE Config Directory Structure

Each scenario contains a `sre-config/` directory with three subdirectories:

```
scenarios/<scenario-name>/sre-config/
├── agents/               # Custom agent definitions
│   └── *.yaml            # api_version: azuresre.ai/v1, kind: AgentConfiguration
├── connectors/           # Data connector definitions
│   └── *.yaml            # api_version: azuresre.ai/v2, kind: DataConnector
└── knowledge-base/       # Runbook documents for agent memory
    └── *.md              # Markdown documents uploaded as knowledge base entries
```

### Agent YAML format

```yaml
api_version: azuresre.ai/v1
kind: AgentConfiguration
metadata:
  name: my-custom-agent
spec:
  # Agent-specific configuration
```

### Connector YAML format

```yaml
api_version: azuresre.ai/v2
kind: DataConnector
metadata:
  name: my-data-connector
spec:
  # Connector-specific configuration
```

### Knowledge Base

Markdown files (`.md`) placed in `knowledge-base/` are uploaded as documents to the agent's memory store. File names are preserved as document identifiers.

## API Reference

The script calls the SRE Agent dataplane v2 API:

| Method | Endpoint | Content-Type | Purpose |
|---|---|---|---|
| `PUT` | `/api/v2/extendedAgent/agents/{name}` | `application/yaml` | Create or update a custom agent |
| `PUT` | `/api/v2/extendedAgent/connectors/{name}` | `application/yaml` | Create or update a data connector |
| `POST` | `/api/v2/extendedAgent/memory/documents` | `application/json` | Upload a knowledge base document |

Authentication uses a Bearer token obtained from:

```bash
az account get-access-token --resource https://management.azure.com
```

## Troubleshooting

### "Azure CLI is not authenticated"

Run `az login` and select the correct subscription with `az account set --subscription <id>`.

### "powershell-yaml module is not installed"

```powershell
Install-Module powershell-yaml -Scope CurrentUser -Force
```

### 401 Unauthorized

Your bearer token may have expired. The script acquires a fresh token on each run, but ensure your `az` session is still valid:

```powershell
az account show  # Should display your account info without errors
```

### 404 Not Found

Verify the `AgentEndpoint` URL is correct and does **not** include a trailing slash or API path — the script appends those automatically.

### "YAML file is missing metadata.name"

Every agent and connector YAML file must include a `metadata.name` field. The script uses this value to build the API path:

```yaml
metadata:
  name: my-resource-name   # ← this is required
```

### Partial failures

The script continues processing all files even if individual uploads fail. Check the summary table at the end for per-file status. The exit code is non-zero if any file failed.
