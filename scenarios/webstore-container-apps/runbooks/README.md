# Runbooks

Operational runbooks for the Cocoa Co Webstore and its SRE Agent.

These are step-by-step guides designed to be followed by both humans and AI agents (Azure SRE Agent) during incident investigation and remediation.

## Available Runbooks

| Runbook | When to Use |
|---------|-------------|
| [Frontend Failure Investigation](frontend-failure-investigation.md) | Elevated error rates on the webstore frontend (4xx/5xx spikes, checkout failures, missing pages) |

## Structure

Each runbook follows a consistent format:

1. **When to Use** — Trigger conditions
2. **Prerequisites** — Required access and tools
3. **Investigation Steps** — Ordered diagnostic workflow
4. **Root Cause Classification** — Common failure categories with signatures and fixes
5. **Remediation** — Priority-ordered fix actions
6. **Verification** — How to confirm the issue is resolved
7. **Reference** — Architecture, key files, common error codes

## Adding New Runbooks

When creating a new runbook:
- Use the same section structure for consistency
- Include concrete CLI commands and telemetry queries
- Document known failure modes with their signatures
- Add the runbook to the table above
