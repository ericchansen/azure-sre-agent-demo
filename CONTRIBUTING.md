# Adding a New Scenario to the Azure SRE Agent Demo Hub

This guide explains how to add a new Azure SRE Agent demo scenario to this repo.

---

## What is a scenario?

A scenario is a self-contained demo that shows Azure SRE Agent detecting and remediating a specific class of failure on a specific Azure workload. Examples:
- A Container App returning 503 (webstore-container-apps)
- An AKS blue/green deployment rolling out a bad build (aks-blue-green)
- An Azure Function timing out, an API Management policy misconfiguration, etc.

One SRE Agent instance (in `infra/sre-agent/`) monitors all scenario resource groups.

---

## Directory layout

Create a new directory under `scenarios/`:

```
scenarios/<your-scenario-slug>/
├── README.md                    # Overview, demo flow, setup guide, variables
├── infra/
│   ├── <cluster-or-app>.bicep   # Bicep for scenario-specific Azure resources
│   └── monitoring/
│       └── <alert>.bicep        # Metric alert that triggers SRE Agent
├── k8s/                         # (AKS scenarios only) Kubernetes manifests
├── app/                         # (If scenario needs a custom app) Dockerfile + code
└── runbooks/
    └── <failure-mode>.md        # Investigation runbook (SRE Agent indexes from GitHub)
```

Use `scenarios/TEMPLATE/` as a starting point.

---

## Naming conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Scenario slug | `kebab-case` | `aks-blue-green` |
| Azure resource group | `rg-<scenario-slug>` | `rg-webstore-aks` |
| GitHub Actions workflows | `<slug>-demo-break.yml`, `<slug>-demo-reset.yml` | `aks-demo-break.yml` |
| Workflow display names | `<Scenario>: Break …`, `<Scenario>: Reset …` | `AKS: Break Deployment` |
| ACR image tags | `<slug>:<version>` | `aks-stub:v1` (pushed to `acrwebstorestaging`) |
| Docs pages | `docs-site/docs/scenarios/<slug>/architecture.md`, `demo-script.md` | |

---

## Step-by-step

### 1. Create the scenario directory

Copy `scenarios/TEMPLATE/` to `scenarios/<your-scenario-slug>/` and fill in the placeholders.

### 2. Write the infra Bicep

- Scenario resources go in `infra/<your-resources>.bicep`
- Alert rule goes in `infra/monitoring/<alert>.bicep`
- Resource group name: `rg-<scenario-slug>`

### 3. Register with the shared SRE Agent

Add your resource group to `infra/sre-agent/bicep/sre-agent.parameters.json`:

```json
"targetResourceGroups": {
  "value": ["rg-webstore-demo", "rg-<your-scenario-slug>"]
}
```

Then redeploy the SRE Agent:

```bash
az deployment sub create \
  --location eastus2 \
  --template-file infra/sre-agent/bicep/minimal-sre-agent.bicep \
  --parameters @infra/sre-agent/bicep/sre-agent.parameters.json
```

### 4. Create GitHub Actions workflows

Create `.github/workflows/<slug>-demo-break.yml` and `.github/workflows/<slug>-demo-reset.yml`.

Follow the OIDC auth pattern in `webstore-demo-break.yml`. Use `environment:` to scope secrets.

### 5. Write a runbook

Create `scenarios/<slug>/runbooks/<failure-mode>.md`. Include:
- What the failure looks like (metrics, logs, traces)
- Investigation steps (what commands/queries to run)
- Expected SRE Agent behavior
- Remediation steps

SRE Agent can index runbooks from connected GitHub repos — include specific error patterns, log snippets, and `kubectl` or `az` commands it can reuse.

### 6. Add docs site pages

Create:
- `docs-site/docs/scenarios/<slug>/architecture.md`
- `docs-site/docs/scenarios/<slug>/demo-script.md`

Add to `docs-site/sidebars.ts` under the `Scenarios` category:

```ts
{
  type: 'category',
  label: 'Your Scenario Name',
  items: [
    'scenarios/<slug>/architecture',
    'scenarios/<slug>/demo-script',
  ],
},
```

### 7. Update the README scenario table

Add a row to the scenarios table in `README.md`.

### 8. Provision Azure resources

1. Create resource group: `az group create -n rg-<slug> -l <region>`
2. Deploy infra: `az deployment group create ...`
3. Configure GitHub Actions environment with required secrets/variables
4. Update SRE Agent `targetResourceGroups` (step 3 above)
5. End-to-end validation: break → alert fires → agent investigates → agent remediates

---

## Checklist

- [ ] `scenarios/<slug>/README.md` with setup guide and variables
- [ ] Infra Bicep (`infra/`) deployed
- [ ] Monitoring alert deployed
- [ ] SRE Agent `targetResourceGroups` updated
- [ ] `<slug>-demo-break.yml` and `<slug>-demo-reset.yml` workflows
- [ ] Runbook in `runbooks/`
- [ ] Docs pages (`architecture.md`, `demo-script.md`)
- [ ] `sidebars.ts` updated
- [ ] `README.md` scenario table updated
- [ ] End-to-end validated
