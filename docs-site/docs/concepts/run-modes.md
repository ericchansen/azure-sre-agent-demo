---
sidebar_position: 2
title: Run Modes
description: Review mode vs Autonomous mode — controlling agent autonomy.
---

# Run Modes

Run modes control whether the agent **asks for approval** before taking actions or **acts on its own**.

> Full reference: [sre.azure.com/docs/concepts/run-modes](https://sre.azure.com/docs/concepts/run-modes)

## Two modes

### Review mode (default)

The agent investigates autonomously, then **proposes** an action for your approval.

```
Agent: "I found that checkout is failing because DEMO_BROKEN_CHECKOUT=true.
        Proposed action: Reset DEMO_BROKEN_CHECKOUT to false.
        [Approve] [Deny]"
```

Only **SRE Agent Administrators** can approve.

### Autonomous mode

The agent investigates **and executes** without waiting.

```
Agent: "I found checkout was failing due to DEMO_BROKEN_CHECKOUT=true.
        Done: I've reset the environment variable. Checkout is now returning 201."
```

## Which to use

| Scenario | Recommended |
|----------|------------|
| Production incidents | **Review** — human in the loop |
| Staging / dev | **Autonomous** — let it fix fast |
| Daily health checks | **Autonomous** |
| Security alerts | **Review** |

## Staying in control

Three mechanisms keep you in control at every layer:

| Mechanism | What it controls |
|-----------|-----------------|
| **RBAC** | What the agent can see and do — scoped through its managed identity and Azure role assignments |
| **Approval gates** | Review mode requires human approval before any infrastructure change executes |
| **Audit trail** | Every investigation step, proposed action, and outcome is logged and traceable |

Together: RBAC controls **scope**, approval gates control **action**, and the audit trail provides **visibility**.

## Getting started in production

:::tip Start with a high-noise, non-critical workload
1. Deploy in **Review mode** against a workload that generates frequent, well-understood alerts
2. Observe what the agent recommends for 2–4 weeks — build confidence in its reasoning
3. As confidence grows, expand to additional workloads
4. Move well-understood patterns to **Autonomous mode** while keeping sensitive workloads in Review
:::

## In this demo

The demo uses **Review mode** by default so you can narrate the agent's proposal and show the Approve/Deny flow. If you want a faster demo, switch to Autonomous and let the audience see the agent fix it hands-free.

## What Review mode gates

Review mode shows Approve/Deny only for **Azure infrastructure operations** (Azure CLI commands, ARM operations, Kubernetes commands). Other actions — querying data, sending notifications — proceed without approval.

For governance over non-Azure actions, use [Hooks](https://sre.azure.com/docs/tutorials/agent-config/agent-hooks).

## Further reading

- [Run Modes — official docs](https://sre.azure.com/docs/concepts/run-modes)
- [Response Plans](https://sre.azure.com/docs/tutorials/agent-config/setup-response-plan)
- [Hooks](https://sre.azure.com/docs/tutorials/agent-config/agent-hooks)
- [Permissions](https://sre.azure.com/docs/concepts/permissions)
