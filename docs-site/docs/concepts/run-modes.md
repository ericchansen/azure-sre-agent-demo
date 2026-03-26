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

:::tip Start with Review
Observe what the agent recommends for 2–4 weeks. When you find patterns you're always approving, switch those specific triggers to Autonomous.
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
