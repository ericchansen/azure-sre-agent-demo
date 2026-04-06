# Scenario: `<Your Scenario Name>`

> Replace this file with a real description. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the full authoring guide.

A brief description of what this scenario demonstrates — the failure mode, the Azure workload, and what Azure SRE Agent does about it.

---

## Demo flow

| Step | What happens | Who does it |
|------|-------------|-------------|
| **1. Baseline** | Everything works. | The app |
| **2. Break** | TODO: describe what the break workflow does. | You (one-click workflow) |
| **3. Detection** | SRE Agent detects the anomaly via Azure Monitor / App Insights. | Azure SRE Agent |
| **4. Investigation** | Agent runs queries, correlates signals. | Azure SRE Agent |
| **5. Remediation** | Agent executes a fix (Review or Autonomous mode). | Azure SRE Agent |
| **6. Recovery** | System returns to healthy state. | The app |

---

## Azure resources

| Resource | Type | Resource Group |
|----------|------|---------------|
| `TODO` | TODO | `rg-<scenario-slug>` |

---

## GitHub Actions variables

**Secrets** (per environment):
| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | App registration client ID (federated credential) |
| `AZURE_TENANT_ID` | Entra ID tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID |

**Variables** (per environment):
| Variable | Example |
|----------|---------|
| `RESOURCE_GROUP` | `rg-<scenario-slug>` |

---

## Workflows

```bash
# Break
gh workflow run "<Scenario>: Break ..." -f environment=<YOUR_ENV>

# Reset
gh workflow run "<Scenario>: Reset ..." -f environment=<YOUR_ENV>
```

---

## Coming soon

- [ ] Infra Bicep
- [ ] Demo workflows
- [ ] Runbook
- [ ] Docs site pages
