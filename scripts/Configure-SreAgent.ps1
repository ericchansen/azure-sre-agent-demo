<#
.SYNOPSIS
    Configures an Azure SRE Agent instance from a scenario's sre-config directory.

.DESCRIPTION
    Reads agent definitions, data connectors, and knowledge base documents from
    a scenario's sre-config/ directory and pushes them to an SRE Agent dataplane
    v2 API endpoint.

    File types processed:
      - sre-config/agents/*.yaml      → PUT /api/v2/extendedAgent/agents/{name}
      - sre-config/connectors/*.yaml   → PUT /api/v2/extendedAgent/connectors/{name}
      - sre-config/knowledge-base/*.md → POST /api/v2/extendedAgent/memory/documents

    Requires the powershell-yaml module for YAML parsing:
      Install-Module powershell-yaml -Scope CurrentUser

.PARAMETER ScenarioPath
    Path to the scenario directory (e.g., ./scenarios/aks-blue-green).
    Must contain a sre-config/ subdirectory.

.PARAMETER AgentEndpoint
    Base URL of the SRE Agent instance (e.g., https://myagent.sre.azure.com).
    No trailing slash.

.PARAMETER DryRun
    Show what would be configured without making any API calls.

.EXAMPLE
    ./scripts/Configure-SreAgent.ps1 `
      -ScenarioPath ./scenarios/aks-blue-green `
      -AgentEndpoint https://myagent.sre.azure.com

.EXAMPLE
    ./scripts/Configure-SreAgent.ps1 `
      -ScenarioPath ./scenarios/webstore-container-apps `
      -AgentEndpoint https://myagent.sre.azure.com `
      -DryRun
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ScenarioPath,

    [Parameter(Mandatory)]
    [string]$AgentEndpoint,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ----------------------------------------------------------------

function Write-Status {
    param([string]$Message, [string]$Color = 'White')
    Write-Host $Message -ForegroundColor $Color
}

function Get-BearerToken {
    $tokenJson = az account get-access-token --resource https://management.azure.com --only-show-errors -o json
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to acquire bearer token. Run 'az login' first."
    }
    return ($tokenJson | ConvertFrom-Json).accessToken
}

function Extract-YamlName {
    param([string]$Content)
    $parsed = ConvertFrom-Yaml $Content
    if ($parsed.metadata -and $parsed.metadata.name) {
        return $parsed.metadata.name
    }
    throw "YAML file is missing metadata.name"
}

function Invoke-SreApi {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Body,
        [string]$ContentType,
        [hashtable]$Headers
    )

    $params = @{
        Method      = $Method
        Uri         = $Uri
        Body        = [System.Text.Encoding]::UTF8.GetBytes($Body)
        ContentType = $ContentType
        Headers     = $Headers
    }

    $response = Invoke-RestMethod @params -StatusCodeVariable 'statusCode' -ResponseHeadersVariable 'respHeaders'
    return @{ StatusCode = $statusCode; Body = $response }
}

# --- Pre-flight checks ------------------------------------------------------

# Check powershell-yaml module
if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
    Write-Status "ERROR: powershell-yaml module is not installed." Red
    Write-Status "Install it with:  Install-Module powershell-yaml -Scope CurrentUser" Yellow
    exit 1
}
Import-Module powershell-yaml -ErrorAction Stop

# Resolve and validate scenario path
$ScenarioPath = Resolve-Path $ScenarioPath -ErrorAction Stop | Select-Object -ExpandProperty Path
$configPath = Join-Path $ScenarioPath 'sre-config'

if (-not (Test-Path $configPath)) {
    Write-Status "ERROR: sre-config/ directory not found at $configPath" Red
    exit 1
}

# Trim trailing slash from endpoint
$AgentEndpoint = $AgentEndpoint.TrimEnd('/')

# Authenticate and acquire token (skip in dry-run — allows offline preview)
$token = $null
if (-not $DryRun) {
    Write-Verbose "Checking Azure CLI authentication..."
    $azAccount = az account show --only-show-errors -o json
    if ($LASTEXITCODE -ne 0) {
        Write-Status "ERROR: Azure CLI is not authenticated. Run 'az login' first." Red
        exit 1
    }
    Write-Verbose "Authenticated as: $(($azAccount | ConvertFrom-Json).user.name)"

    Write-Verbose "Acquiring bearer token..."
    $token = Get-BearerToken
}

$headers = @{ Authorization = "Bearer $token" }

# --- Processing --------------------------------------------------------------

# Results tracker: list of [PSCustomObject]@{ File; Type; Status; Detail }
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$failureCount = 0

# ---- Agents ----
$agentDir = Join-Path $configPath 'agents'
if (Test-Path $agentDir) {
    $agentFiles = Get-ChildItem $agentDir -Filter '*.yaml' -File
    foreach ($file in $agentFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            $name = Extract-YamlName $content
            $uri = "$AgentEndpoint/api/v2/extendedAgent/agents/$name"

            if ($DryRun) {
                Write-Status "[DRY-RUN] Would PUT agent '$name' from $($file.Name)" Yellow
                $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'Agent'; Status = 'skipped (dry-run)'; Detail = $uri })
                continue
            }

            Write-Verbose "Uploading agent '$name' from $($file.Name)..."
            Invoke-SreApi -Method PUT -Uri $uri -Body $content -ContentType 'application/yaml' -Headers $headers | Out-Null
            Write-Status "  ✓ Agent '$name' configured" Green
            $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'Agent'; Status = 'success'; Detail = '' })
        }
        catch {
            $failureCount++
            $detail = $_.Exception.Message
            Write-Status "  ✗ Agent '$($file.Name)' failed: $detail" Red
            $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'Agent'; Status = 'failed'; Detail = $detail })
        }
    }
}
else {
    Write-Verbose "No agents directory found at $agentDir — skipping."
}

# ---- Connectors ----
$connectorDir = Join-Path $configPath 'connectors'
if (Test-Path $connectorDir) {
    $connectorFiles = Get-ChildItem $connectorDir -Filter '*.yaml' -File
    foreach ($file in $connectorFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            $name = Extract-YamlName $content
            $uri = "$AgentEndpoint/api/v2/extendedAgent/connectors/$name"

            if ($DryRun) {
                Write-Status "[DRY-RUN] Would PUT connector '$name' from $($file.Name)" Yellow
                $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'Connector'; Status = 'skipped (dry-run)'; Detail = $uri })
                continue
            }

            Write-Verbose "Uploading connector '$name' from $($file.Name)..."
            Invoke-SreApi -Method PUT -Uri $uri -Body $content -ContentType 'application/yaml' -Headers $headers | Out-Null
            Write-Status "  ✓ Connector '$name' configured" Green
            $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'Connector'; Status = 'success'; Detail = '' })
        }
        catch {
            $failureCount++
            $detail = $_.Exception.Message
            Write-Status "  ✗ Connector '$($file.Name)' failed: $detail" Red
            $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'Connector'; Status = 'failed'; Detail = $detail })
        }
    }
}
else {
    Write-Verbose "No connectors directory found at $connectorDir — skipping."
}

# ---- Knowledge Base ----
$kbDir = Join-Path $configPath 'knowledge-base'
if (Test-Path $kbDir) {
    $kbFiles = Get-ChildItem $kbDir -Filter '*.md' -File
    $uri = "$AgentEndpoint/api/v2/extendedAgent/memory/documents"

    foreach ($file in $kbFiles) {
        try {
            $content = Get-Content $file.FullName -Raw
            $body = @{ filename = $file.Name; content = $content } | ConvertTo-Json -Depth 4

            if ($DryRun) {
                Write-Status "[DRY-RUN] Would POST knowledge doc '$($file.Name)'" Yellow
                $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'KnowledgeBase'; Status = 'skipped (dry-run)'; Detail = $uri })
                continue
            }

            Write-Verbose "Uploading knowledge doc '$($file.Name)'..."
            Invoke-SreApi -Method POST -Uri $uri -Body $body -ContentType 'application/json' -Headers $headers | Out-Null
            Write-Status "  ✓ Knowledge doc '$($file.Name)' uploaded" Green
            $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'KnowledgeBase'; Status = 'success'; Detail = '' })
        }
        catch {
            $failureCount++
            $detail = $_.Exception.Message
            Write-Status "  ✗ Knowledge doc '$($file.Name)' failed: $detail" Red
            $results.Add([PSCustomObject]@{ File = $file.Name; Type = 'KnowledgeBase'; Status = 'failed'; Detail = $detail })
        }
    }
}
else {
    Write-Verbose "No knowledge-base directory found at $kbDir — skipping."
}

# --- Summary -----------------------------------------------------------------

Write-Host ""
Write-Host "── Summary ──────────────────────────────────────────────" -ForegroundColor Cyan
$results | Format-Table -Property File, Type, Status, Detail -AutoSize | Out-String | Write-Host

if ($failureCount -gt 0) {
    Write-Status "$failureCount file(s) failed. See details above." Red
    exit 1
}

$totalCount = $results.Count
if ($DryRun) {
    Write-Status "Dry run complete — $totalCount file(s) would be processed." Yellow
}
else {
    Write-Status "All $totalCount file(s) configured successfully." Green
}
