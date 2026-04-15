---
title: Frontend Failure Investigation
scenario: webstore-container-apps
failure_mode: multiple
severity: high
tags: [container-apps, nextjs, postgresql, prisma, checkout, e-commerce]
---

# Frontend Failure Investigation — Cocoa & Co. Webstore

## Prerequisites

Ensure access to the following Azure resources before starting investigation:

| Resource | Type | Name |
|----------|------|------|
| Resource Group | Microsoft.Resources/resourceGroups | `rg-webstore-demo` |
| Container App | Microsoft.App/containerApps | `ca-webstore-staging` |
| App Insights | Microsoft.Insights/components | `appi-webstore-staging` |
| PostgreSQL | Microsoft.DBforPostgreSQL/flexibleServers | `psql-webstore-staging` |
| Container Registry | Microsoft.ContainerRegistry/registries | `acrwebstorestaging` |

## Architecture

```
┌─────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│   Browser    │────▶│  ca-webstore-staging  │────▶│ psql-webstore-staging│
│  (Customer)  │◀────│  (Next.js on ACA)     │◀────│  (PostgreSQL Flex)   │
└─────────────┘     └──────────────────────┘     └─────────────────────┘
                           │        │
                           │        ▼
                           │   ┌──────────┐
                           │   │ External │
                           │   │ Payment  │
                           │   │ Gateway  │
                           │   └──────────┘
                           ▼
                    ┌──────────────────┐
                    │appi-webstore-    │
                    │staging           │
                    │(App Insights)    │
                    └──────────────────┘
```

**Key source files:**
- `src/app/api/orders/route.ts` — Order creation API (most failure-prone)
- `src/app/api/cart/route.ts` — Cart management API
- `prisma/schema.prisma` — Database schema with FK constraints
- `instrumentation.ts` — OpenTelemetry configuration

## Alert Information

| Alert | Condition | Severity |
|-------|-----------|----------|
| Failed Requests - appi-webstore-staging | Failed request count exceeds baseline threshold | High |

When this alert fires, begin investigation at Step 1.

## Step 1 — Correlate Telemetry with CorrelateTimeSeries

Run these KQL queries against `appi-webstore-staging` to classify the failure pattern.

### 1.1 Failures by HTTP Result Code

```kql
requests
| where timestamp > ago(1h)
| summarize
    total = count(),
    failed = countif(success == false)
    by bin(timestamp, 5m), resultCode
| order by timestamp desc
```

Interpretation:
- **Mostly 503** → Service error. Check env vars (Category A) or resource exhaustion (Category E).
- **Mostly 404** → Missing routes (Category C). Lower severity.
- **Mostly 500** → Unhandled exceptions. Check exception telemetry (Step 1.3).
- **Mixed codes** → Multiple failure modes active. Investigate each separately.

### 1.2 Failures by Operation Name

```kql
requests
| where timestamp > ago(1h) and success == false
| summarize failCount = count() by operation_Name, resultCode
| order by failCount desc
```

Interpretation:
- **POST /api/orders dominates** → Checkout-specific failure. Likely Category A (DEMO_BROKEN_CHECKOUT).
- **All operations affected equally** → Infrastructure issue. Likely Category D or E.
- **GET /about, /contact, etc.** → Missing routes (Category C).

### 1.3 Exception Telemetry

```kql
exceptions
| where timestamp > ago(1h)
| summarize count() by type, outerMessage
| order by count_ desc
```

Look for:
- `PaymentGatewayConnectionRefused` → DEMO_BROKEN_CHECKOUT is enabled (Category A).
- `PrismaClientKnownRequestError` with code P2003, P1008, P2025 → Database issues (Category B).
- `PrismaClientInitializationError` → Database connection failure (Category B/E).

### 1.4 Dependency Failures

```kql
dependencies
| where timestamp > ago(1h) and success == false
| summarize failCount = count() by target, type, resultCode
| order by failCount desc
```

Interpretation:
- PostgreSQL dependency failures → Category B or E.
- External service failures → Category D.

## Step 2 — Quantify Impact

```kql
requests
| where timestamp > ago(1h)
| summarize
    totalRequests = count(),
    failedRequests = countif(success == false),
    failureRate = round(100.0 * countif(success == false) / count(), 2),
    p50_ms = percentile(duration, 50),
    p95_ms = percentile(duration, 95),
    p99_ms = percentile(duration, 99),
    affectedUsers = dcount(client_IP)
| project totalRequests, failedRequests, failureRate, p50_ms, p95_ms, p99_ms, affectedUsers
```

Record these values before and after remediation to demonstrate recovery.

## Step 3 — Root Cause Classification

### Category A: Configuration / Feature Flag (P0)

**Trigger:** DEMO_BROKEN_CHECKOUT environment variable set to `true`.

**Behavior:** All `POST /api/orders` requests return HTTP 503 with body:
```json
{"error": "PaymentGatewayConnectionRefused", "status": 503}
```

**Verification:**
```bash
az containerapp show -n ca-webstore-staging -g rg-webstore-demo \
  --query "properties.template.containers[0].env[?name=='DEMO_BROKEN_CHECKOUT']"
```

**Remediation:**
```bash
az containerapp update -n ca-webstore-staging -g rg-webstore-demo \
  --set-env-vars DEMO_BROKEN_CHECKOUT=false
```

**Expected recovery time:** 1–2 minutes (new revision deploys automatically).

### Category B: Database / Prisma Errors (P1)

**Common Prisma error codes:**

| Code | Name | Meaning | Likely Cause |
|------|------|---------|--------------|
| P1008 | Operations timed out | Database did not respond within timeout | PostgreSQL overloaded, network issue, or connection pool exhausted |
| P2003 | Foreign key constraint failed | FK reference points to nonexistent row | Stale product IDs in cart after product deletion |
| P2025 | Record not found | Expected record does not exist | Race condition between read and write; deleted between operations |
| P2002 | Unique constraint failed | Duplicate key violation | Duplicate order submission |
| P2024 | Timed out fetching connection from pool | Connection pool exhausted | Too many concurrent connections |

**Verification — check PostgreSQL health:**
```bash
az postgres flexible-server show -n psql-webstore-staging -g rg-webstore-demo \
  --query "{state:state, version:version, sku:sku.name}"
```

**Remediation by error:**
- **P1008 / P2024**: Check PostgreSQL CPU/memory metrics. Consider scaling the server SKU or increasing connection pool size in the application's `DATABASE_URL`.
- **P2003**: Investigate data integrity. Cart items reference product IDs that no longer exist. Clear affected cart entries or restore missing products.
- **P2025**: Usually transient. If persistent, check application logic for race conditions in `src/app/api/orders/route.ts`.

### Category C: Missing Routes — 404s (P2)

**Affected paths:** `/about`, `/contact`, `/shipping`, `/returns`

These paths are linked in the UI footer/navigation but have no corresponding Next.js route handlers. This is a known application gap, not an infrastructure incident.

**Verification:**
```kql
requests
| where timestamp > ago(1h) and resultCode == "404"
| summarize count() by url
| order by count_ desc
```

**Remediation:** Create the missing Next.js pages or remove the links from the UI. File a GitHub issue for the development team. No infrastructure action required.

### Category D: Downstream Service Failures (P1)

**Indicators:** Dependency failures in App Insights for non-PostgreSQL targets.

**Verification:**
```kql
dependencies
| where timestamp > ago(1h) and success == false and type != "SQL"
| summarize count() by target, type, resultCode
```

**Remediation:** Downstream failures are external. Document the dependency, check the external service's status page, and implement circuit breaker patterns if not already present.

### Category E: Resource Exhaustion (P0)

**Indicators:** 503s across ALL endpoints (not just /api/orders), high response times (p95 > 5s), Container App CPU > 80% or memory > 80%.

**Verification:**
```bash
az containerapp show -n ca-webstore-staging -g rg-webstore-demo \
  --query "properties.template.containers[0].resources"

az monitor metrics list --resource \
  "/subscriptions/{sub}/resourceGroups/rg-webstore-demo/providers/Microsoft.App/containerApps/ca-webstore-staging" \
  --metric "UsageNanoCores" --interval PT5M --start-time (now - 1h)
```

**Remediation:**
```bash
# Scale out
az containerapp update -n ca-webstore-staging -g rg-webstore-demo \
  --min-replicas 2 --max-replicas 10

# Or increase per-container resources
az containerapp update -n ca-webstore-staging -g rg-webstore-demo \
  --cpu 1.0 --memory 2.0Gi
```

## Remediation Priority

| Priority | Category | Action | Recovery Time |
|----------|----------|--------|---------------|
| P0 | A — Config flag | Remove DEMO_BROKEN_CHECKOUT env var | 1–2 min |
| P0 | E — Resource exhaustion | Scale Container App replicas or resources | 2–5 min |
| P1 | B — Database errors | Fix PostgreSQL health or data integrity | 5–30 min |
| P1 | D — Downstream failures | Monitor external service; add circuit breakers | Varies |
| P2 | C — Missing routes | File issue for dev team; no infra action | N/A |
| P3 | Architecture | Add health checks, retry logic, connection pooling | Sprint-level |

## Verification Checklist

After applying remediation, confirm recovery using these steps:

1. **Re-run failure rate query** (Step 2) — failure rate should be dropping toward 0%.
2. **Test affected endpoint** — For checkout fixes, send a test `POST /api/orders` and confirm HTTP 200.
3. **Check new revision health** — After env var changes, verify the new Container App revision is Running:
   ```bash
   az containerapp revision list -n ca-webstore-staging -g rg-webstore-demo \
     --query "[?properties.runningState=='Running'].{name:name, created:properties.createdTime}" -o table
   ```
4. **Monitor 5–10 minutes** — Confirm no recurrence of failures in App Insights live metrics.
5. **Record before/after metrics** — Document total requests, failure rate, and p95 latency for the incident report.

## Known Failure Modes Reference

| Environment Variable | Value | Effect | Affected Endpoint |
|---------------------|-------|--------|-------------------|
| DEMO_BROKEN_CHECKOUT | `true` | All orders return 503 PaymentGatewayConnectionRefused | POST /api/orders |
| DATABASE_URL | missing/invalid | All DB operations fail with PrismaClientInitializationError | All /api/* routes |
| NODE_ENV | not set | Development mode; verbose errors exposed to clients | All routes |

## Common Prisma Error Codes Quick Reference

| Code | Category | Description |
|------|----------|-------------|
| P1000 | Connection | Authentication failed against database |
| P1001 | Connection | Cannot reach database server |
| P1002 | Connection | Database server reached but timed out |
| P1008 | Connection | Operations timed out |
| P2002 | Query | Unique constraint violation |
| P2003 | Query | Foreign key constraint violation |
| P2024 | Connection | Timed out fetching connection from pool |
| P2025 | Query | Record not found for operation |
