# Azure SRE Agent — Bug Report

**Date:** March 11, 2026 (Day 1 after GA, March 10, 2026)
**Agent:** sre-sandbox
**Region:** eastus2
**Resource Group:** rg-sre
**Subscription:** ME-MngEnvMCAP529863-erichansen-1 (f7858112-5c13-46e5-8341-3851a12164fa)
**Reporter:** Eric Hansen, Sr. Solutions Engineer, Microsoft

---

## Bug 1: Unrecoverable "Internal Model Connection Error" Loop

### Severity: High

### Summary
After a successful onboarding conversation and autonomous investigation, the agent entered an unrecoverable error state where every subsequent user message triggers "a temporary AI model connection error." The agent never recovered, even after multiple retries over ~10 minutes.

### Steps to Reproduce
1. Created a new GA SRE Agent ("sre-sandbox") at sre.azure.com
2. Connected 4 GitHub repos via OAuth, configured resource group access
3. Agent initiated onboarding: read READMEs, created memory files (`team.md`, `overview.md`), ran Azure CLI commands (`az containerapp list`, `az containerapp show`), and produced a detailed investigation report
4. User sent follow-up messages asking about cold start behavior and resource group cleanup
5. **Every subsequent agent response failed** with "temporary AI model connection error"
6. Auto-retry mechanism triggered 3 times — all failed
7. Thread became permanently stuck; no further agent responses possible

### Expected Behavior
- Agent should recover from transient model connection errors via retry/backoff
- If the backing model is unavailable, the agent should provide a clear status message (e.g., "Service temporarily unavailable, please try again in a few minutes")
- The conversation thread should remain functional after recovery

### Actual Behavior
- Agent entered a permanent error loop with no recovery
- User had to abandon the thread entirely and start a new one
- No error details exposed to the user — just a generic "temporary AI model connection error"
- The auto-retry messages ("My last request failed due to a temporary AI model connection error. Please retry processing my previous request.") also all failed

### Timestamps
- ~1:18 PM PT: Successful onboarding + investigation completed
- ~1:24 PM PT: First user follow-up message → "internal error"
- ~1:25 PM PT: Auto-retry #1 → failed
- ~1:25 PM PT: Auto-retry #2 → failed
- ~1:33 PM PT: Auto-retry #3 → failed
- Thread permanently stuck after this point

### Impact
- First-run experience broken within minutes of GA
- User's first real questions after onboarding went completely unanswered
- Lost context from the onboarding investigation (agent had found a real ACR auth issue in rg-prod — 34K+ ImagePullBackOff retries — but user couldn't ask follow-up questions about it)

---

## Bug 2: Agent Misidentifies Its Own UI as a Customer App

### Severity: Medium

### Summary
When the user shared a screenshot of the broken SRE Agent chat thread (Bug 1 above) in a new conversation, the agent misidentified its own portal UI as the "Itemwise app" and attempted to investigate a non-existent application error.

### Steps to Reproduce
1. Take a screenshot of the broken SRE Agent chat (showing the error loop from Bug 1)
2. Start a new chat thread in the same SRE Agent
3. Send the screenshot to the agent

### Expected Behavior
- Agent should recognize its own chat UI in the screenshot
- Or at minimum, not confidently misidentify it as a specific monitored application

### Actual Behavior
- Agent responded: *"The screenshot shows the Itemwise app returning an error: 'I'm sorry, I encountered an error processing your request. Please try again.'"*
- Agent then read its `overview.md` memory file and started investigating Itemwise's Container Apps deployment
- User had to explicitly correct the agent: *"No, that's not the itemwise app. That's you! That's another chat thread with you"*

### Root Cause Hypothesis
The agent's image analysis appears to:
1. Detect an error message in the screenshot
2. Pattern-match against known applications from memory (Itemwise was in `overview.md`)
3. Confidently (but incorrectly) attribute the error to the closest application match
4. Not consider that the screenshot could be of the SRE Agent's own UI

---

## Bug 3: Agent Cannot Self-Diagnose from Screenshots of Its Own Errors

### Severity: Low (feature request / improvement)

### Summary
After being corrected that the screenshot was of its own chat, the agent still could not extract meaningful diagnostic information from the image. It acknowledged seeing "another Azure SRE Agent chat thread" but could not read the error text or identify the failure mode.

### Conversation Transcript

**User:** "Based on the image, can you ask yourself what was wrong with Azure SRE Agent?"

**Agent:** *"Looking at the screenshot, I can see another Azure SRE Agent chat thread where the agent appears to have run into issues during a conversation... It looks like the agent may have been **getting stuck or failing during task execution** — possibly looping, encountering tool errors, or not completing its work properly. However, I'll be honest — I can't read all the fine text in the screenshot clearly enough to pinpoint the exact error or behavior."*

### Expected Behavior
- Agent should have access to its own conversation logs, error logs, or session history
- When asked "what went wrong in my other thread?", the agent should be able to query its own backend for error details rather than trying to OCR a screenshot
- This is especially important since the errors were on the agent's backend — it should have more diagnostic visibility than the user does

### Suggested Improvement
Expose a self-diagnostic skill or command (e.g., `/diagnose` or `#check-errors`) that allows the agent to:
- Query recent conversation history across threads
- Check model availability/health status
- Report known issues or service degradations
- Access its own Application Insights telemetry

---

## Context: What Was Working Well

To be fair, the agent's first-run experience up until the error loop was **impressive**:

- **Deep Context worked great**: Agent autonomously read READMEs from all 4 connected repos, created structured memory files
- **Investigation was thorough**: Ran `az containerapp list`, `az containerapp show` for multiple apps across resource groups, identified a real ACR authentication issue (admin user disabled → 34K+ ImagePullBackOff retries since March 1)
- **Memory creation was useful**: Created `team.md` and `overview.md` with accurate, structured summaries
- **Onboarding conversation was natural**: The "let me get to know you" flow felt productive, not forced

The bugs above are specific to error handling and self-awareness, not the core investigation capabilities.

---

## Environment Details

| Component | Value |
|-----------|-------|
| Agent name | sre-sandbox |
| Agent type | GA (created March 11, 2026 — Day 1) |
| Region | eastus2 |
| Connected repos | teamskills, itemwise, foundry-agents-lifecycle, azure-idp-workshop |
| GitHub connector | OAuth (not PAT) |
| Resource groups monitored | rg-teamskills-prod, rg-prod, rg-itemwise-prod, rg-sre |
| Logs connector | None (using built-in Azure Monitor) |
| Browser | Microsoft Edge on Windows 11 |

---

## Appendix: Full Conversation Transcripts

### Thread 1: "Team onboarding" (original — contains Bug 1)

**AGENT (onboarding):** Read READMEs, created memory files, ran Azure CLI investigation, found ACR auth issue in rg-prod.

**USER (msg 1):** "Well, I'm a senior solutions engineer here at Microsoft. I work in pre-sales and I support customers with building on Azure..."

**USER (msg 2):** "...sometimes when I spin up team skills or other apps, it seems like they fail, and I don't quite know why yet. I'm thinking that it takes a while for the front end to warm up..."

**USER (msg 3):** "I wonder if one of those resource groups for team skills is actually outdated and not in use anymore and should have been cleaned up..."

**USER (msg 4):** "My last request failed due to a temporary AI model connection error. Please retry processing my previous request." ❌

**USER (msg 5):** "My last request failed due to a temporary AI model connection error. Please retry processing my previous request." ❌

**USER (msg 6):** "My last request failed due to a temporary AI model connection error. Please retry processing my previous request." ❌

### Thread 2: "SRE Agent Investigation" (self-diagnosis attempt — contains Bugs 2 & 3)

**USER:** [Sent screenshot of broken Thread 1]

**AGENT:** "The screenshot shows the Itemwise app returning an error..." ← **WRONG** (Bug 2)

**USER:** "No, that's not the itemwise app. That's you! That's another chat thread with you"

**AGENT:** "I can see the screenshot now. It shows another chat thread with me... Could you tell me more about what specifically isn't working?"

**USER:** "Based on the image, can you ask yourself what was wrong with Azure SRE Agent?"

**AGENT:** "I'll be honest — I can't read all the fine text in the screenshot clearly enough to pinpoint the exact error or behavior." ← (Bug 3)
