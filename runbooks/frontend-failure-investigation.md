# Runbook: Frontend Failure Investigation

> **Scope:** Cocoa Co Webstore (Next.js on Azure Container Apps)  
> **Environments:** `rg-webstore-staging`, `rg-webstore-prod`  
> **Telemetry:** Application Insights (`appi-webstore-staging`)  
> **Last validated:** 2026-03-31

## When to Use This Runbook

- Users or monitoring report elevated error rates on the webstore frontend.
- Azure Monitor fires a **Failed Requests** or **Failure Anomalies** alert on the webstore Application Insights resource.
- You observe increased 4xx/5xx responses from the Container App.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Azure RBAC | Reader on `rg-webstore-staging` and/or `rg-webstore-prod` |
| Application Insights | `appi-webstore-staging` (staging) — production currently has no App Insights |
| Source code access | `ericchansen/webstore` GitHub repository |
| Tools | Azure CLI, Application Insights query tools, GitHub access |

---

## Step 1 — Identify Scope and Discover Resources

**Goal:** Confirm which environment is affected and enumerate the relevant Azure resources.

### Actions

1. List resources in the affected resource group(s):
   ```
   az resource list --resource-group rg-webstore-staging --subscription <sub-id> --query "[].{name:name, type:type}" -o table
   az resource list --resource-group rg-webstore-prod --subscription <sub-id> --query "[].{name:name, type:type}" -o table
   ```
2. Identify the key resources:
   - **Container App:** `ca-webstore-staging` or `ca-webstore-prod`
   - **Application Insights:** `appi-webstore-staging` (staging only)
   - **PostgreSQL:** `psql-webstore-staging` or `psql-webstore-prod`
   - **Container Registry:** `acrwebstorestaging` or `acrwebstoreprod`

3. Confirm the Container App is running:
   ```
   az containerapp show --name ca-webstore-staging --resource-group rg-webstore-staging --subscription <sub-id> \
     --query "{name:name, fqdn:properties.configuration.ingress.fqdn, latestRevision:properties.latestRevisionName, runningStatus:properties.runningStatus, provisioningState:properties.provisioningState}" -o json
   ```

### Expected Output

- `provisioningState: Succeeded`, `runningStatus: Running`
- If the app is not running, escalate to the Container Apps restart/deployment runbook before continuing.

---

## Step 2 — Check for Active Alerts

**Goal:** Determine if Azure Monitor has already flagged the issue.

### Actions

1. List metric alerts in the resource group:
   ```
   az monitor metrics alert list --resource-group rg-webstore-staging --subscription <sub-id> -o json
   ```
2. Note any alerts with `enabled: true` and review their:
   - Threshold and evaluation frequency
   - Scoped resource (should be the App Insights resource)
   - Recent fire history

### Key Alert: Failed Requests

- **Name:** `Failed Requests - appi-webstore-staging`
- **Condition:** >1 failed request in a 1-minute window
- **Severity:** 3 (Warning)
- **Purpose:** Near-instant detection for demo/low-traffic environments

---

## Step 3 — Correlate Failure Time Series

**Goal:** Understand the failure distribution by HTTP status code and by operation (endpoint).

This is the most important diagnostic step. Use Application Insights `CorrelateTimeSeries` with the following data sets:

### 3a — Failures by Result Code

```json
{
  "table": "requests",
  "filters": ["success=\"false\""],
  "splitBy": "resultCode"
}
```

Look for:
- **500s** — Server-side crashes (unhandled exceptions, database errors)
- **503s** — Service unavailable (downstream dependency failures, resource exhaustion)
- **404s** — Missing routes or resources
- **4xxs** — Client errors (validation, auth)

### 3b — Failures by Operation Name

```json
{
  "table": "requests",
  "filters": ["success=\"false\""],
  "splitBy": "operation_Name"
}
```

Look for:
- Which API routes or pages are most affected
- Whether failures are concentrated on a single endpoint or spread across the app
- RSC (React Server Component) failures indicating frontend rendering issues

### 3c — Exceptions and Dependency Failures

```json
[
  {"table": "exceptions", "splitBy": "type"},
  {"table": "dependencies", "filters": ["success=\"false\""], "splitBy": "type"}
]
```

Look for:
- **Prisma errors** (P2003 = FK violation, P1008 = operation timeout, P2025 = record not found)
- **PostgreSQL dependency failures** — indicates database connectivity or data integrity issues
- **InProc dependency failures** — internal processing errors in the Next.js server
- **HTTP dependency failures** — external service calls failing (Stripe, etc.)

### Recommended Time Range

- Default to last 24 hours for initial triage.
- Narrow to the spike window once anomalies are identified.

---

## Step 4 — Quantify Impact

**Goal:** Determine how many requests and instances are affected.

Use Application Insights `GetImpact` for each major failure category:

### 4a — Overall Failure Impact

```json
{"table": "requests", "filters": ["success=\"false\""]}
```

### 4b — Per-Status-Code Impact

Run separately for each significant status code found in Step 3:
```json
{"table": "requests", "filters": ["resultCode=\"500\""]}
{"table": "requests", "filters": ["resultCode=\"503\""]}
```

### Key Metrics to Capture

| Metric | What It Tells You |
|--------|-------------------|
| `impactedCount` / `totalCount` | Failure rate (%) |
| `impactedInstances` / `totalInstances` | How many container replicas are affected |
| `impactedCountPercent` | Quick severity gauge: <5% minor, 5-20% significant, >20% critical |

---

## Step 5 — Inspect Distributed Traces

**Goal:** Get the actual exception messages and stack traces for root cause identification.

### 5a — List Failing Traces

For each major failure type, list representative traces:

```json
{"table": "requests", "filters": ["success=\"false\"", "resultCode=\"500\""]}
{"table": "requests", "filters": ["success=\"false\"", "resultCode=\"503\""]}
{"table": "exceptions", "filters": ["type=\"P2003\""]}
```

### 5b — Inspect Individual Traces

For each representative `traceId` and `spanId` returned, use `GetDistributedTrace` to inspect the full call tree.

### What to Look For in Trace Details

| Field | Significance |
|-------|--------------|
| `outerType` | Exception class (e.g., `P2003`, `Error`, `TypeError`) |
| `outerMessage` | Human-readable error description |
| `innermostMessage` | Root cause message (often the most useful) |
| `method` | Code location where the error originated |
| `details[].rawStack` | Full stack trace for code-level diagnosis |
| `cloud_RoleInstance` | Which container replica produced the error |

---

## Step 6 — Classify Root Causes

Based on the telemetry gathered above, classify each failure into one of these categories:

### Category A: Configuration / Feature Flag Issues

**Signature:** Consistent failures on a specific endpoint, error message references a known toggle or environment variable.

**Example from this codebase:**
- `DEMO_BROKEN_CHECKOUT=true` causes all `POST /api/orders` to return 503 with `PaymentGatewayConnectionRefused`
- Located in `src/app/api/orders/route.ts` lines 51-85

**Remediation:** Update the Container App environment variable:
```
az containerapp update --name <app-name> --resource-group <rg> --subscription <sub-id> \
  --set-env-vars DEMO_BROKEN_CHECKOUT=false
```

**Verification:** Confirm the env var is updated:
```
az containerapp show --name <app-name> --resource-group <rg> --subscription <sub-id> \
  --query "properties.template.containers[0].env[?name=='DEMO_BROKEN_CHECKOUT']" -o json
```

### Category B: Database / Data Integrity Issues

**Signature:** Prisma P2003 (FK constraint), P2025 (record not found), P1008 (timeout), PostgreSQL errors.

**Example from this codebase:**
- `Foreign key constraint violated on the constraint: OrderItem_productId_fkey`
- Stale cart data references product IDs that no longer exist in the `Product` table
- Located in `src/app/api/orders/route.ts` at `prisma.order.create()`

**Remediation:**
1. **Immediate:** Verify database connectivity and check if products were recently deleted/re-seeded.
2. **Code fix:** Add server-side validation of product IDs before `prisma.order.create()` — query `prisma.product.findMany()` with the submitted IDs and return a 400 for any that are missing.
3. **PR template:** See the fix pattern in webstore PR #23.

### Category C: Missing Routes / Pages

**Signature:** 404 errors on page routes (not API routes), consistent across all instances.

**Example from this codebase:**
- `/about`, `/contact`, `/shipping`, `/returns` return 404
- Links exist in the UI (footer/nav) but no corresponding `src/app/<route>/page.tsx` files exist

**Remediation:** Either create the missing pages or remove the dead links from the UI components.

### Category D: Downstream Service Failures

**Signature:** 502/503 errors, elevated latency before failure, dependency failures to external services (Stripe, etc.).

**Remediation:** Check external service status pages. Implement circuit breakers and retry logic with backoff. Consider fallback responses for non-critical dependencies.

### Category E: Resource Exhaustion

**Signature:** 503 errors across all endpoints, high CPU/memory metrics, OOM kills in container logs.

**Remediation:** Scale up replicas or container resources. Investigate memory leaks or CPU-intensive operations. Check Container App CPU and memory metrics.

---

## Step 7 — Remediate

**Goal:** Apply fixes in priority order.

### Priority Order

| Priority | Type | Action | Impact |
|----------|------|--------|--------|
| P0 | Config fix | Update env vars / app settings via `az containerapp update` | Immediate |
| P0 | Rollback | Roll back to previous Container App revision if deployment caused issue | Immediate |
| P1 | Code fix | Open PR with validation/error handling fixes | Next deploy |
| P2 | Missing features | Create placeholder pages / remove dead links | Next deploy |
| P3 | Architecture | Add circuit breakers, retry logic, caching | Planned work |

### For Each Remediation

1. **Document the current state** before making changes.
2. **Apply the fix** (env var update, code change, scaling adjustment).
3. **Verify the fix** by re-checking the env var, metrics, or endpoint.
4. **Monitor for 15-30 minutes** to confirm the failure rate drops.

---

## Step 8 — Document and Track

**Goal:** Create a paper trail for the investigation.

### GitHub Issue

Create an issue on the `ericchansen/webstore` repo with:
- Summary of the failure rate and impact
- Each root cause as a separate finding with status (mitigated / open / low priority)
- Telemetry evidence: trace IDs, exception types, error counts
- Impact table: error code, count, % of traffic, endpoint, status

### Pull Request (if code fix needed)

Open a PR with:
- Clear description of what failed and why
- The specific code change (e.g., validation logic)
- Testing instructions
- Reference to the GitHub issue (`Closes #N`)

---

## Step 9 — Verify Resolution

**Goal:** Confirm that the failure rate has returned to baseline.

### Actions

1. Wait 15-30 minutes after remediation.
2. Re-run the CorrelateTimeSeries queries from Step 3 with a narrow time window (last 1 hour).
3. Verify:
   - Failed request count has dropped to near zero (or baseline noise level)
   - No new exception types have appeared
   - Container App health is stable
4. If an Azure Monitor alert was firing, verify it has auto-resolved or close it manually.

---

## Reference: Webstore Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌───────────────────┐
│   Browser /     │────▶│  Container App   │────▶│   PostgreSQL      │
│   Client        │     │  (Next.js)       │     │   (Prisma ORM)    │
│                 │◀────│  ca-webstore-*   │◀────│   psql-webstore-* │
└─────────────────┘     └──────────────────┘     └───────────────────┘
                               │
                               ▼
                        ┌──────────────────┐
                        │  App Insights    │
                        │  appi-webstore-* │
                        └──────────────────┘
```

### Key Source Files

| File | Purpose |
|------|---------|
| `src/app/api/orders/route.ts` | Order creation API — most failure-prone endpoint |
| `src/app/api/cart/route.ts` | Cart management API |
| `prisma/schema.prisma` | Database schema — defines FK constraints |
| `src/app/api/health/route.ts` | Health check endpoint |
| `instrumentation.ts` | OpenTelemetry instrumentation setup |

### Known Failure Modes

| Env Var | Effect | Status Code |
|---------|--------|-------------|
| `DEMO_BROKEN_CHECKOUT=true` | All checkout requests fail with fake payment gateway error | 503 |

### Common Prisma Error Codes

| Code | Meaning | Likely Cause in Webstore |
|------|---------|-------------------------|
| P2003 | Foreign key constraint violated | Stale product IDs in cart/order |
| P1008 | Operations timed out | PostgreSQL connectivity or performance |
| P2025 | Record not found | Deleted product referenced by ID |
| P2002 | Unique constraint violation | Duplicate order number (unlikely with random generation) |

---

## Appendix: Quick Reference Commands

### Check Container App env vars
```bash
az containerapp show --name <app> --resource-group <rg> --subscription <sub-id> \
  --query "properties.template.containers[0].env" -o json
```

### Update Container App env var
```bash
az containerapp update --name <app> --resource-group <rg> --subscription <sub-id> \
  --set-env-vars KEY=value
```

### Check Container App revisions
```bash
az containerapp revision list --name <app> --resource-group <rg> --subscription <sub-id> \
  --query "[].{name:name, active:properties.active, created:properties.createdTime, traffic:properties.trafficWeight}" -o table
```

### Get App Insights resource ID
```bash
az resource show --name appi-webstore-staging --resource-group rg-webstore-staging \
  --resource-type Microsoft.Insights/components --subscription <sub-id> \
  --query id -o tsv
```
