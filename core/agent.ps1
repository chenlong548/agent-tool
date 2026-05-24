<#
Agent Tool - AI Engineering Workflow Engine
Version: 4.0
Description: Workflow engine that manages 12 AI engineering skills across 7 layers with programmatic phase validation, human alignment enforcement, feedback loop support, validation severity system, deployment decision engine, log rotation, workflow metrics, state-driven workflow, Repair Orchestration, Regression Protection, Retry Budget, Human Escalation.
#>

$agentsDir = ".agents"
$stateDir = ".agents\state"
$contextDir = ".agents\context"
$docsDir = ".\docs"
$projectDir = ".\project"

$phaseFile = "$stateDir\current_phase.json"
$activeTasksFile = "$stateDir\active_tasks.json"
$blockedTasksFile = "$stateDir\blocked_tasks.json"
$riskRegistryFile = "$stateDir\risk_registry.json"
$executionStateFile = "$stateDir\execution_state.json"
$metricsFile = "$stateDir\workflow_metrics.json"
$retryBudgetFile = "$stateDir\retry_budget.json"

$validPhases = @("idle", "understanding", "alignment", "planning", "execution", "validation", "repair", "release", "completed")

$phaseTransitions = @{
    "idle"        = @("understanding")
    "understanding" = @("alignment", "planning")
    "alignment"  = @("planning", "understanding")
    "planning"   = @("execution", "alignment")
    "execution"  = @("validation", "planning", "alignment")
    "validation" = @("release", "repair", "execution", "planning", "alignment")
    "repair"     = @("execution", "validation", "planning", "alignment")
    "release"    = @("completed", "execution")
    "completed"  = @("idle")
}

$phaseLabels = @{
    "idle"        = "Layer 0 - Idle"
    "understanding" = "Layer 1 - Understanding"
    "alignment"  = "Layer 1.5 - Human Alignment"
    "planning"   = "Layer 2 - Planning"
    "execution"  = "Layer 3 - Execution"
    "validation" = "Layer 4 - Validation"
    "repair"     = "Layer 3.5 - Repair & Recovery"
    "release"    = "Layer 5 - Release"
    "completed"  = "Workflow Complete"
}

$severityLevels = @("P0", "P1", "P2", "P3")
$decisionLevels = @("SAFE_TO_DEPLOY", "DEPLOY_WITH_MONITORING", "REQUIRES_REWORK", "BLOCK_RELEASE")

function Get-LogDirectory {
    param([string]$baseDir)
    $logDir = "$baseDir/logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    $hotDir = "$logDir/hot"
    if (-not (Test-Path $hotDir)) { New-Item -ItemType Directory -Path $hotDir -Force | Out-Null }
    return $hotDir
}

function Get-LogRootDirectory {
    param([string]$baseDir)
    $logDir = "$baseDir/logs"
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    return $logDir
}

function Write-Log {
    param([string]$message, [string]$level = "INFO")
    $local:logDir = Get-LogDirectory -baseDir $agentsDir
    $today = Get-Date -Format "yyyy-MM-dd"
    $logFile = "$local:logDir\$today.log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$level] $message"
    if (-not (Test-Path $local:logDir)) { New-Item -ItemType Directory -Path $local:logDir -Force | Out-Null }
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    Write-Host $logEntry
}

function Invoke-LogRotation {
    $local:logDir = Get-LogRootDirectory -baseDir $agentsDir
    $hotDir = "$local:logDir\hot"
    $warmDir = "$local:logDir\warm"
    $coldDir = "$local:logDir\cold"
    if (-not (Test-Path $hotDir)) { New-Item -ItemType Directory -Path $hotDir -Force | Out-Null }
    if (-not (Test-Path $warmDir)) { New-Item -ItemType Directory -Path $warmDir -Force | Out-Null }
    if (-not (Test-Path $coldDir)) { New-Item -ItemType Directory -Path $coldDir -Force | Out-Null }

    $now = Get-Date
    $hotLimit = $now.AddDays(-1)
    $warmLimit = $now.AddDays(-3)

    Get-ChildItem -Path $hotDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $hotLimit } | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $warmDir -Force
        Write-Log "Log rotated: HOT -> WARM ($($_.Name))" "DEBUG"
    }
    Get-ChildItem -Path $warmDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $warmLimit } | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $coldDir -Force
        Write-Log "Log rotated: WARM -> COLD ($($_.Name))" "DEBUG"
    }
    Get-ChildItem -Path $coldDir -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt $now.AddDays(-7) } | ForEach-Object {
        Remove-Item -Path $_.FullName -Force
        Write-Log "Log expired: COLD removed ($($_.Name))" "DEBUG"
    }

    $rootLogs = Get-ChildItem -Path $local:logDir -File -Filter "*.log" -ErrorAction SilentlyContinue
    foreach ($log in $rootLogs) {
        $destPath = "$hotDir\$($log.Name)"
        try {
            if (-not (Test-Path $destPath)) {
                Move-Item -Path $log.FullName -Destination $hotDir -Force
            } else {
                Remove-Item -Path $log.FullName -Force
            }
        } catch {
            # Another agent process may still be writing this log; leave it for the next run.
        }
    }
}

function Expand-File {
    param([string]$SourcePath, [string]$DestinationPath)
    try {
        $shell = New-Object -ComObject Shell.Application
        $zipFile = $shell.NameSpace((Resolve-Path $SourcePath).Path)
        $destFolder = $shell.NameSpace((Resolve-Path $DestinationPath).Path)
        $destFolder.CopyHere($zipFile.Items(), 16)
        return $true
    } catch {
        Write-Log "Error expanding file: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-CurrentPhase {
    if (Test-Path $phaseFile) {
        $state = Get-Content $phaseFile -Raw | ConvertFrom-Json
        return $state.phase
    }
    return "idle"
}

function Set-CurrentPhase {
    param([string]$phase, [string]$skill = "", [string]$workflow = "")
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $state = @{
        phase = $phase
        workflow = $workflow
        layer = $phaseLabels[$phase]
        skill = $skill
        started_at = $now
        last_updated = $now
        status = "active"
        next_action = "execute_skill"
    }
    $state | ConvertTo-Json -Depth 5 | Set-Content $phaseFile -Encoding UTF8
    Write-Log "Phase updated: $phase (skill: $skill, workflow: $workflow)"
}

function Get-JsonState {
    param([string]$FilePath, $Default = @{})
    if (Test-Path $FilePath) {
        try {
            return Get-Content $FilePath -Raw | ConvertFrom-Json
        } catch {
            return $Default
        }
    }
    return $Default
}

function Set-JsonState {
    param([string]$FilePath, $Data)
    $Data | ConvertTo-Json -Depth 10 | Set-Content $FilePath -Encoding UTF8
}

function Get-ProjectCodeFiles {
    if (-not (Test-Path $projectDir)) { return @() }
    return @(Get-ChildItem -Path $projectDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".gitkeep" })
}

function Add-BlockedTask {
    param([string]$Reason, [string]$Category = "waiting_user_input", [string]$Severity = "P1", [string]$Phase = "")
    $state = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @(); total = 0; blocked_reasons = @{ waiting_user_input = @(); waiting_dependency = @(); risk_high = @(); error_occurred = @(); manual_review_required = @() } }
    $task = @{
        id = "BLK-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        reason = $Reason
        category = $Category
        severity = $Severity
        phase = if ($Phase) { $Phase } else { Get-CurrentPhase }
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "blocked"
    }
    $state.tasks += $task
    $state.total = $state.tasks.Count
    if ($state.blocked_reasons.PSObject.Properties.Name -contains $Category) {
        $state.blocked_reasons.$Category += $task.id
    }
    Set-JsonState -FilePath $blockedTasksFile -Data $state
    Write-Log "Blocked task added: [$Severity] $Reason (category: $Category)" "WARNING"
    return $task
}

function Remove-BlockedTask {
    param([string]$TaskId)
    $state = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @(); total = 0; blocked_reasons = @{ waiting_user_input = @(); waiting_dependency = @(); risk_high = @(); error_occurred = @(); manual_review_required = @() } }
    $state.tasks = @($state.tasks | Where-Object { $_.id -ne $TaskId -and $_.status -ne "resolved" })
    foreach ($cat in $state.blocked_reasons.PSObject.Properties.Name) {
        $state.blocked_reasons.$cat = @($state.blocked_reasons.$cat | Where-Object { $_ -ne $TaskId })
    }
    $state.total = $state.tasks.Count
    Set-JsonState -FilePath $blockedTasksFile -Data $state
    Write-Log "Blocked task resolved: $TaskId"
}

function Add-Risk {
    param([string]$Description, [string]$Severity = "high", [string]$Category = "architecture", [string]$Phase = "")
    $state = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); total = 0; by_severity = @{ critical = @(); high = @(); medium = @(); low = @() }; mitigation_required = @() }
    $risk = @{
        id = "RSK-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        description = $Description
        severity = $Severity
        category = $Category
        phase = if ($Phase) { $Phase } else { Get-CurrentPhase }
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        status = "open"
    }
    $state.risks += $risk
    $state.total = $state.risks.Count
    if ($state.by_severity.PSObject.Properties.Name -contains $Severity) {
        $state.by_severity.$Severity += $risk.id
    }
    if ($Severity -eq "critical" -or $Severity -eq "high") {
        $state.mitigation_required += $risk.id
    }
    Set-JsonState -FilePath $riskRegistryFile -Data $state
    Write-Log "Risk registered: [$Severity] $Description (category: $Category)" "WARNING"
    return $risk
}

function Resolve-Risk {
    param([string]$RiskId)
    $state = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); total = 0; by_severity = @{ critical = @(); high = @(); medium = @(); low = @() }; mitigation_required = @() }
    $newRisks = @()
    foreach ($risk in $state.risks) {
        if ($risk.id -eq $RiskId) {
            $resolvedRisk = @{
                id = $risk.id
                description = $risk.description
                severity = $risk.severity
                category = $risk.category
                phase = $risk.phase
                created_at = $risk.created_at
                status = "resolved"
                resolved_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            $newRisks += $resolvedRisk
        } else {
            $newRisks += $risk
        }
    }
    $state.risks = $newRisks
    $state.mitigation_required = @($state.mitigation_required | Where-Object { $_ -ne $RiskId })
    foreach ($sev in $state.by_severity.PSObject.Properties.Name) {
        $state.by_severity.$sev = @($state.by_severity.$sev | Where-Object { $_ -ne $RiskId })
    }
    Set-JsonState -FilePath $riskRegistryFile -Data $state
    Write-Log "Risk resolved: $RiskId"
}

function Get-DeploymentDecision {
    $decision = "SAFE_TO_DEPLOY"
    $reasons = @()

    $riskState = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); mitigation_required = @() }
    $criticalRisks = @($riskState.risks | Where-Object { $_.severity -eq "critical" -and $_.status -eq "open" })
    $highRisks = @($riskState.risks | Where-Object { $_.severity -eq "high" -and $_.status -eq "open" })
    if ($criticalRisks.Count -gt 0) {
        $decision = "BLOCK_RELEASE"
        $reasons += "P0 critical risks unresolved: $($criticalRisks.Count)"
    }
    if ($highRisks.Count -gt 0 -and $decision -ne "BLOCK_RELEASE") {
        $decision = "REQUIRES_REWORK"
        $reasons += "P1 high risks unresolved: $($highRisks.Count)"
    }

    $blockedState = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @() }
    $activeBlocked = @($blockedState.tasks | Where-Object { $_.status -eq "blocked" })
    if ($activeBlocked.Count -gt 0 -and $decision -ne "BLOCK_RELEASE") {
        $decision = "REQUIRES_REWORK"
        $reasons += "Blocked tasks active: $($activeBlocked.Count)"
    }

    if (Test-Path "$docsDir\QA_AUDIT_REPORT.md") {
        $qaReport = Get-Content "$docsDir\QA_AUDIT_REPORT.md" -Raw
        if ($qaReport -match "BLOCK_RELEASE|BLOCKED") {
            $decision = "BLOCK_RELEASE"
            $reasons += "QA report explicitly blocks release"
        } elseif ($qaReport -match "REQUIRES_REWORK|REWORK") {
            if ($decision -ne "BLOCK_RELEASE") {
                $decision = "REQUIRES_REWORK"
                $reasons += "QA report requires rework"
            }
        } elseif ($qaReport -match "DEPLOY_WITH_MONITORING|MONITOR") {
            if ($decision -eq "SAFE_TO_DEPLOY") {
                $decision = "DEPLOY_WITH_MONITORING"
                $reasons += "QA report recommends monitoring"
            }
        }
    }

    return @{ Decision = $decision; Reasons = $reasons }
}

function Record-PhaseTransition {
    param([string]$From, [string]$To, [string]$Type = "forward", [string]$Reason = "")
    $state = Get-JsonState -FilePath $executionStateFile -Default @{ current_execution = $null; history = @(); statistics = @{ total_executions = 0; successful = 0; failed = 0; retried = 0 }; last_execution = $null }
    $entry = @{
        id = "EXE-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        from_phase = $From
        to_phase = $To
        transition_type = $Type
        reason = $Reason
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $state.history += $entry
    if ($state.history.Count -gt 100) { $state.history = $state.history[-100..-1] }
    $state.statistics.total_executions++
    if ($Type -eq "forward") { $state.statistics.successful++ }
    elseif ($Type -eq "feedback") { $state.statistics.retried++ }
    elseif ($Type -eq "blocked") { $state.statistics.failed++ }
    $state.last_execution = $entry
    $state.current_execution = @{ phase = $To; started_at = $entry.timestamp; type = $Type }
    Set-JsonState -FilePath $executionStateFile -Data $state
}

function Update-WorkflowMetrics {
    param([string]$Action, [string]$Phase = "", [hashtable]$Details = @{})
    $state = Get-JsonState -FilePath $metricsFile -Default @{ phase_durations = @{}; transition_counts = @{}; feedback_counts = @{}; validation_failures = @{}; total_phase_transitions = 0; total_feedback_loops = 0; created_at = ""; last_updated = "" }
    if (-not $state.created_at) { $state.created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
    $state.last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ($Action -eq "transition") {
        $key = "$($Details.from)_to_$($Details.to)"
        $currentVal = 0
        if ($state.transition_counts.PSObject.Properties.Name -contains $key) {
            $currentVal = $state.transition_counts.$key
        }
        $state.transition_counts | Add-Member -NotePropertyName $key -NotePropertyValue ($currentVal + 1) -Force
        $state.total_phase_transitions++
    }
    elseif ($Action -eq "feedback") {
        $key = "$($Details.from)_to_$($Details.to)"
        $currentVal = 0
        if ($state.feedback_counts.PSObject.Properties.Name -contains $key) {
            $currentVal = $state.feedback_counts.$key
        }
        $state.feedback_counts | Add-Member -NotePropertyName $key -NotePropertyValue ($currentVal + 1) -Force
        $state.total_feedback_loops++
    }
    elseif ($Action -eq "validation_failed") {
        $key = $Phase
        $currentVal = 0
        if ($state.validation_failures.PSObject.Properties.Name -contains $key) {
            $currentVal = $state.validation_failures.$key
        }
        $state.validation_failures | Add-Member -NotePropertyName $key -NotePropertyValue ($currentVal + 1) -Force
    }
    elseif ($Action -eq "phase_duration") {
        $key = $Phase
        if ($Details.duration_seconds) {
            if (-not $state.phase_durations.PSObject.Properties.Name -contains $key) {
                $state.phase_durations | Add-Member -NotePropertyName $key -NotePropertyValue @{ total_seconds = 0; count = 0; avg_seconds = 0 }
            }
            $state.phase_durations.$key.total_seconds += $Details.duration_seconds
            $state.phase_durations.$key.count++
            $state.phase_durations.$key.avg_seconds = [math]::Round($state.phase_durations.$key.total_seconds / $state.phase_durations.$key.count, 1)
        }
    }

    Set-JsonState -FilePath $metricsFile -Data $state
}

function Test-PhasePrerequisites {
    param([string]$targetPhase)

    $currentPhase = Get-CurrentPhase
    $errors = @()

    $riskState = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); mitigation_required = @() }
    $criticalRisks = @($riskState.risks | Where-Object { $_.severity -eq "critical" -and $_.status -eq "open" })
    if ($criticalRisks.Count -gt 0 -and $targetPhase -in @("execution", "validation", "release")) {
        $errors += "BLOCKED by critical risks ($($criticalRisks.Count) unresolved). Resolve with: agent risk resolve <id>"
    }

    $blockedState = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @() }
    $phaseBlocked = @($blockedState.tasks | Where-Object { $_.status -eq "blocked" -and $_.phase -eq $targetPhase })
    if ($phaseBlocked.Count -gt 0) {
        $errors += "BLOCKED by $($phaseBlocked.Count) blocked task(s) targeting this phase. Resolve with: agent unblock <id>"
    }

    if ($targetPhase -eq "understanding") {
        if (-not (Test-Path $docsDir)) { $errors += "docs/ directory not found. Run 'agent init' first." }
    }

    elseif ($targetPhase -eq "alignment") {
        if (-not (Test-Path "$docsDir\REQUIREMENTS.md") -and -not (Test-Path "$docsDir\CHANGE_REQUIREMENTS.md")) {
            $errors += "No requirements document found. Complete Layer 1 (Understanding) first."
        }
    }

    elseif ($targetPhase -eq "planning") {
        if (-not (Test-Path "$docsDir\REQUIREMENTS.md") -and -not (Test-Path "$docsDir\SYSTEM_UNDERSTANDING.md")) {
            $errors += "No understanding documents found. Complete Layer 1 first."
        }
        if (Test-Path "$docsDir\REQUIREMENTS.md") {
            if (-not (Test-Path "$docsDir\PLANNING_ALIGNMENT_QUESTIONS.md")) {
                $errors += "PLANNING_ALIGNMENT_QUESTIONS.md not found. Complete Layer 1.5 (Alignment) first."
            }
            if (-not (Test-Path "$docsDir\HUMAN_CONFIRMATION_CHECKLIST.md")) {
                $errors += "HUMAN_CONFIRMATION_CHECKLIST.md not found. Human confirmation required before planning."
            } else {
                $checklist = Get-Content "$docsDir\HUMAN_CONFIRMATION_CHECKLIST.md" -Raw
                if ($checklist -match "\[ \]" -or $checklist -match "pending|unconfirmed|not.confirmed") {
                    $errors += "HUMAN_CONFIRMATION_CHECKLIST.md has unconfirmed items. All items must be confirmed before planning."
                }
            }
            if (-not (Test-Path "$docsDir\MVP_SCOPE_BOUNDARY.md")) {
                $errors += "MVP_SCOPE_BOUNDARY.md not found. Define MVP scope before planning."
            }
        }
    }

    elseif ($targetPhase -eq "execution") {
        if (-not (Test-Path "$docsDir\PROJECT_PLAN.md") -and -not (Test-Path "$docsDir\MODIFICATION_PLAN.md")) {
            $errors += "No plan document found. Complete Layer 2 (Planning) first."
        }
    }

    elseif ($targetPhase -eq "validation") {
        if (-not (Test-Path $projectDir)) {
            $errors += "project/ directory not found. Complete Layer 3 (Execution) first."
        }
        $projectFiles = Get-ProjectCodeFiles
        if ($projectFiles.Count -eq 0) {
            $errors += "project/ directory is empty. Complete Layer 3 (Execution) first."
        }
    }

    elseif ($targetPhase -eq "repair") {
        if (-not (Test-Path "$docsDir\QA_AUDIT_REPORT.md") -and -not (Test-Path "$docsDir\CODE_REVIEW_REPORT.md")) {
            $errors += "No QA report found. Repair requires QA findings to analyze."
        }
    }

    elseif ($targetPhase -eq "release") {
        if (-not (Test-Path "$docsDir\QA_AUDIT_REPORT.md") -and -not (Test-Path "$docsDir\CODE_REVIEW_REPORT.md")) {
            $errors += "No QA report found. Complete Layer 4 (Validation) first."
        }
        $deployDecision = Get-DeploymentDecision
        if ($deployDecision.Decision -eq "BLOCK_RELEASE") {
            $errors += "Deployment decision: BLOCK_RELEASE. Reasons: $($deployDecision.Reasons -join '; ')"
        }
        elseif ($deployDecision.Decision -eq "REQUIRES_REWORK") {
            $errors += "Deployment decision: REQUIRES_REWORK. Reasons: $($deployDecision.Reasons -join '; ')"
        }
    }

    return $errors
}

function Get-RetryBudget {
    $default = @{
        total_retries = 0
        max_total = 10
        by_severity = @{
            P0 = @{ current = 0; max = 2; escalated = $false }
            P1 = @{ current = 0; max = 3; escalated = $false }
            P2 = @{ current = 0; max = 3; escalated = $false }
            P3 = @{ current = 0; max = 1; escalated = $false }
        }
        consecutive_failures = 0
        last_escalation = ""
        history = @()
    }
    return Get-JsonState -FilePath $retryBudgetFile -Default $default
}

function Add-RetryAttempt {
    param([string]$Severity = "P1", [string]$Description = "", [string]$Result = "failed")
    $budget = Get-RetryBudget
    $budget.total_retries++

    $sevKey = $Severity.ToUpper()
    if ($budget.by_severity.PSObject.Properties.Name -contains $sevKey) {
        $budget.by_severity.$sevKey.current++
    }

    if ($Result -eq "failed") {
        $budget.consecutive_failures++
    } else {
        $budget.consecutive_failures = 0
        if ($budget.by_severity.PSObject.Properties.Name -contains $sevKey) {
            $budget.by_severity.$sevKey.current = 0
        }
    }

    $entry = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        severity = $Severity
        description = $Description
        result = $Result
        total_after = $budget.total_retries
    }
    $budget.history += $entry
    if ($budget.history.Count -gt 50) { $budget.history = $budget.history[-50..-1] }

    $escalationNeeded = $false
    $escalationReason = ""

    if ($budget.total_retries -ge $budget.max_total) {
        $escalationNeeded = $true
        $escalationReason = "Total retry budget exceeded ($($budget.total_retries)/$($budget.max_total))"
    }

    if ($budget.by_severity.PSObject.Properties.Name -contains $sevKey) {
        $sevBudget = $budget.by_severity.$sevKey
        if ($sevBudget.current -ge $sevBudget.max -and -not $sevBudget.escalated) {
            $escalationNeeded = $true
            $escalationReason = "$sevKey retry budget exceeded ($($sevBudget.current)/$($sevBudget.max))"
            $budget.by_severity.$sevKey.escalated = $true
        }
    }

    if ($budget.consecutive_failures -ge 3) {
        $escalationNeeded = $true
        $escalationReason = "Consecutive failures exceeded threshold ($($budget.consecutive_failures))"
    }

    if ($escalationNeeded) {
        $budget.last_escalation = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    Set-JsonState -FilePath $retryBudgetFile -Data $budget

    if ($escalationNeeded) {
        Add-Risk -Description "ESCALATION: $escalationReason" -Severity "critical" -Category "retry_budget"
        Add-BlockedTask -Reason "Human escalation required: $escalationReason" -Category "risk_high" -Severity "P0" -Phase "repair"
        Write-Log "ESCALATION TRIGGERED: $escalationReason" "CRITICAL"
    }

    return @{ budget = $budget; escalation_needed = $escalationNeeded; escalation_reason = $escalationReason }
}

function Reset-RetryBudget {
    $default = @{
        total_retries = 0
        max_total = 10
        by_severity = @{
            P0 = @{ current = 0; max = 2; escalated = $false }
            P1 = @{ current = 0; max = 3; escalated = $false }
            P2 = @{ current = 0; max = 3; escalated = $false }
            P3 = @{ current = 0; max = 1; escalated = $false }
        }
        consecutive_failures = 0
        last_escalation = ""
        history = @()
    }
    Set-JsonState -FilePath $retryBudgetFile -Data $default
    Write-Log "Retry budget reset"
}

Invoke-LogRotation

Write-Host "Agent Tool v4.0 - AI Engineering Workflow Engine"
Write-Host "=================================================="

if ($args.Length -eq 0 -or $args[0] -eq $null) {
    Write-Host "Usage: agent <command> [subcommand] [args]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  init                       Initialize project structure"
    Write-Host "  phase status               Show current workflow phase"
    Write-Host "  phase next [phase]         Advance to next phase (with validation)"
    Write-Host "  phase back [phase]         Go back to a previous phase"
    Write-Host "  validate [phase]           Validate prerequisites for a phase"
    Write-Host "  status                     Show full workflow status overview"
    Write-Host "  risk add <sev> <desc>      Register a risk (sev: critical/high/medium/low)"
    Write-Host "  risk resolve <id>          Resolve a risk"
    Write-Host "  risk list                  List all risks"
    Write-Host "  block <reason>             Block current phase with a reason"
    Write-Host "  unblock <id>               Unblock a blocked task"
    Write-Host "  blocked                    List all blocked tasks"
    Write-Host "  decision                   Show deployment decision for current phase"
    Write-Host "  metrics                    Show workflow metrics"
    Write-Host "  log <message>              Record an activity to the log"
    Write-Host "  unzip <file>               Extract compressed log files"
    Write-Host "  help                       Show this help message"
    Write-Host ""
    Write-Host "Repair & Recovery:"
    Write-Host "  repair start              Start a repair cycle (from validation phase)"
    Write-Host "  repair complete           Mark repair as completed successfully"
    Write-Host "  repair fail <sev> [desc]  Record a failed repair attempt"
    Write-Host "  repair status             Show repair and retry budget status"
    Write-Host "  regression run            Execute regression validation"
    Write-Host "  regression status         Check regression report status"
    Write-Host "  retry status              Show retry budget status"
    Write-Host "  retry reset               Reset retry budget to defaults"
    Write-Host "  escalation check          Check escalation conditions"
    exit 1
}

$command = [string]$args[0]

if ($command -eq "init") {
    Write-Log "Initializing AI Engineering project..."

    $scriptPath = $MyInvocation.MyCommand.Definition
    $toolDir = Split-Path -Path $scriptPath -Parent
    $toolSkillsDir = "$toolDir\..\.agents\skills"
    $toolAgentsMd = "$toolDir\..\AGENTS.md"

    if (-not (Test-Path $agentsDir)) {
        New-Item -ItemType Directory -Path $agentsDir -Force | Out-Null
        Write-Log "Created $agentsDir directory"
    }

    $local:logDir = "$agentsDir\logs"
    if (-not (Test-Path $local:logDir)) { New-Item -ItemType Directory -Path $local:logDir -Force | Out-Null }
    $hotDir = "$local:logDir\hot"
    $warmDir = "$local:logDir\warm"
    $coldDir = "$local:logDir\cold"
    if (-not (Test-Path $hotDir)) { New-Item -ItemType Directory -Path $hotDir -Force | Out-Null }
    if (-not (Test-Path $warmDir)) { New-Item -ItemType Directory -Path $warmDir -Force | Out-Null }
    if (-not (Test-Path $coldDir)) { New-Item -ItemType Directory -Path $coldDir -Force | Out-Null }
    Write-Log "Created HOT/WARM/COLD log directories"

    $skillsDir = "$agentsDir\skills"
    if (-not (Test-Path $skillsDir)) { New-Item -ItemType Directory -Path $skillsDir -Force | Out-Null }

    if (Test-Path $toolSkillsDir) {
        $toolSkillsDirResolved = (Resolve-Path $toolSkillsDir).Path
        $skillsDirResolved = (Resolve-Path $skillsDir).Path
        if ($toolSkillsDirResolved -ne $skillsDirResolved) {
            $skillDirs = Get-ChildItem -Path $toolSkillsDir -Directory
            foreach ($skillDir in $skillDirs) {
                $destSkillDir = "$skillsDir\$($skillDir.Name)"
                if (-not (Test-Path $destSkillDir)) { New-Item -ItemType Directory -Path $destSkillDir -Force | Out-Null }
                Copy-Item -Path "$($skillDir.FullName)\*" -Destination $destSkillDir -Recurse -Force
                Write-Log "Copied skill: $($skillDir.Name)"
            }
        } else { Write-Log "Skipping skill copy: same directory" }
    }

    $toolStateDir = "$toolDir\..\.agents\state"
    if (-not (Test-Path $stateDir)) { New-Item -ItemType Directory -Path $stateDir -Force | Out-Null }
    if (Test-Path $toolStateDir) {
        $toolStateDirResolved = (Resolve-Path $toolStateDir).Path
        $stateDirResolved = (Resolve-Path $stateDir).Path
        if ($toolStateDirResolved -ne $stateDirResolved) {
            Get-ChildItem -Path $toolStateDir -File | ForEach-Object { Copy-Item -Path $_.FullName -Destination $stateDir -Force; Write-Log "Copied state: $($_.Name)" }
        }
    }
    if (-not (Test-Path $blockedTasksFile)) {
        Set-JsonState -FilePath $blockedTasksFile -Data @{ tasks = @(); total = 0; blocked_reasons = @{ waiting_user_input = @(); waiting_dependency = @(); risk_high = @(); error_occurred = @(); manual_review_required = @() } }
        Write-Log "Created state: blocked_tasks.json"
    }
    if (-not (Test-Path $riskRegistryFile)) {
        Set-JsonState -FilePath $riskRegistryFile -Data @{ risks = @(); total = 0; by_severity = @{ critical = @(); high = @(); medium = @(); low = @() }; mitigation_required = @() }
        Write-Log "Created state: risk_registry.json"
    }

    $toolContextDir = "$toolDir\..\.agents\context"
    if (-not (Test-Path $contextDir)) { New-Item -ItemType Directory -Path $contextDir -Force | Out-Null }
    if (Test-Path $toolContextDir) {
        $toolContextDirResolved = (Resolve-Path $toolContextDir).Path
        $contextDirResolved = (Resolve-Path $contextDir).Path
        if ($toolContextDirResolved -ne $contextDirResolved) {
            Get-ChildItem -Path $toolContextDir -File | ForEach-Object { Copy-Item -Path $_.FullName -Destination $contextDir -Force; Write-Log "Copied context: $($_.Name)" }
        }
    }

    if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null; Write-Log "Created docs/ directory" }
    if (-not (Test-Path $projectDir)) { New-Item -ItemType Directory -Path $projectDir -Force | Out-Null; Write-Log "Created project/ directory" }

    if (Test-Path $toolAgentsMd) {
        $toolAgentsMdResolved = (Resolve-Path $toolAgentsMd).Path
        $destAgentsMd = (Resolve-Path ".").Path + "\AGENTS.md"
        if ($toolAgentsMdResolved -ne $destAgentsMd) {
            Copy-Item -Path $toolAgentsMd -Destination ".\AGENTS.md" -Force
            Write-Log "Copied AGENTS.md to project root"
        }
    }

    $toolRulesDir = "$toolDir\..\.agents\rules"
    if (Test-Path $toolRulesDir) {
        $rulesFiles = @(
            @{ Src = "$toolRulesDir\CLAUDE.md"; Dst = ".\CLAUDE.md"; Tool = "Claude Code" },
            @{ Src = "$toolRulesDir\.cursorrules"; Dst = ".\.cursorrules"; Tool = "Cursor" },
            @{ Src = "$toolRulesDir\.windsurfrules"; Dst = ".\.windsurfrules"; Tool = "Windsurf" },
            @{ Src = "$toolRulesDir\.clinerules"; Dst = ".\.clinerules"; Tool = "Cline" },
            @{ Src = "$toolRulesDir\.aider.conf.yml"; Dst = ".\.aider.conf.yml"; Tool = "Aider" }
        )
        foreach ($rf in $rulesFiles) {
            if (Test-Path $rf.Src) {
                Copy-Item -Path $rf.Src -Destination $rf.Dst -Force
                Write-Log "Generated rule file: $($rf.Dst) ($($rf.Tool))"
            }
        }

        $traeRulesDir = ".\.trae\rules"
        if (-not (Test-Path $traeRulesDir)) { New-Item -ItemType Directory -Path $traeRulesDir -Force | Out-Null }
        if (Test-Path "$toolRulesDir\.trae\rules\project_rules.md") {
            Copy-Item -Path "$toolRulesDir\.trae\rules\project_rules.md" -Destination "$traeRulesDir\project_rules.md" -Force
            Write-Log "Generated rule file: .trae/rules/project_rules.md (TRAE IDE)"
        }

        $githubDir = ".\.github"
        if (-not (Test-Path $githubDir)) { New-Item -ItemType Directory -Path $githubDir -Force | Out-Null }
        if (Test-Path "$toolRulesDir\.github\copilot-instructions.md") {
            Copy-Item -Path "$toolRulesDir\.github\copilot-instructions.md" -Destination "$githubDir\copilot-instructions.md" -Force
            Write-Log "Generated rule file: .github/copilot-instructions.md (GitHub Copilot)"
        }
    }

    Set-CurrentPhase -phase "idle" -workflow "initialized"

    Write-Log "Initialization completed!"
    Write-Host ""
    Write-Host "  .agents/skills/   - 12 Skill definitions"
    Write-Host "  .agents/state/    - Workflow state machine (phase + risks + blocks + metrics)"
    Write-Host "  .agents/context/  - Compressed long-term context"
    Write-Host "  .agents/logs/     - Execution logs (hot/warm/cold with auto-rotation)"
    Write-Host "  docs/             - Generated documents"
    Write-Host "  project/          - Project code"
    Write-Host "  AGENTS.md         - AI orchestrator entry point"
    Write-Host ""
    Write-Host "  AI Tool Rule Files Generated:"
    Write-Host "    AGENTS.md                        (Codex CLI)"
    Write-Host "    CLAUDE.md                        (Claude Code)"
    Write-Host "    .cursorrules                     (Cursor)"
    Write-Host "    .trae/rules/project_rules.md     (TRAE IDE)"
    Write-Host "    .github/copilot-instructions.md  (GitHub Copilot)"
    Write-Host "    .windsurfrules                   (Windsurf)"
    Write-Host "    .clinerules                      (Cline)"
    Write-Host "    .aider.conf.yml                  (Aider)"
    Write-Host ""
    Write-Host "  Workflow: agent phase next understanding  (start Layer 1)"

} elseif ($command -eq "phase") {
    $subCommand = if ($args.Length -ge 2) { [string]$args[1] } else { "" }

    if ($subCommand -eq "status" -or $subCommand -eq "") {
        $currentPhase = Get-CurrentPhase
        $label = $phaseLabels[$currentPhase]
        Write-Host "Current Phase: $label"
        Write-Host "Phase Key:     $currentPhase"
        if (Test-Path $phaseFile) {
            $state = Get-Content $phaseFile -Raw | ConvertFrom-Json
            if ($state.workflow) { Write-Host "Workflow:      $($state.workflow)" }
            if ($state.skill) { Write-Host "Active Skill:  $($state.skill)" }
            if ($state.last_updated) { Write-Host "Last Updated:  $($state.last_updated)" }
        }
        Write-Host ""
        $allowed = $phaseTransitions[$currentPhase]
        Write-Host "Allowed transitions: $($allowed -join ', ')"

        $riskState = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); mitigation_required = @() }
        $openRisks = @($riskState.risks | Where-Object { $_.status -eq "open" })
        if ($openRisks.Count -gt 0) {
            Write-Host ""
            Write-Host "Active Risks: $($openRisks.Count) open"
            foreach ($r in $openRisks) {
                Write-Host "  [$($r.severity.ToUpper())] $($r.id): $($r.description)"
            }
        }

        $blockedState = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @() }
        $activeBlocked = @($blockedState.tasks | Where-Object { $_.status -eq "blocked" })
        if ($activeBlocked.Count -gt 0) {
            Write-Host ""
            Write-Host "Blocked Tasks: $($activeBlocked.Count) active"
            foreach ($b in $activeBlocked) {
                Write-Host "  [$($b.severity)] $($b.id): $($b.reason)"
            }
        }

    } elseif ($subCommand -eq "next") {
        $targetPhase = if ($args.Length -ge 3) { [string]$args[2] } else { "" }
        if ($targetPhase -eq "") {
            $currentPhase = Get-CurrentPhase
            $allowed = $phaseTransitions[$currentPhase]
            Write-Host "Current phase: $currentPhase"
            Write-Host "Allowed next phases: $($allowed -join ', ')"
            Write-Host "Usage: agent phase next <phase>"
            exit 1
        }

        $currentPhase = Get-CurrentPhase
        $allowed = $phaseTransitions[$currentPhase]

        if ($allowed -notcontains $targetPhase) {
            Write-Log "BLOCKED: Cannot transition from '$currentPhase' to '$targetPhase'" "ERROR"
            Write-Host "BLOCKED: Transition from '$currentPhase' to '$targetPhase' is not allowed."
            Write-Host "Allowed transitions from '$currentPhase': $($allowed -join ', ')"
            exit 1
        }

        $errors = Test-PhasePrerequisites -targetPhase $targetPhase
        if ($errors.Count -gt 0) {
            Write-Log "BLOCKED: Prerequisites not met for '$targetPhase'" "ERROR"
            Write-Host "BLOCKED: Cannot advance to '$targetPhase'. Missing prerequisites:"
            foreach ($err in $errors) {
                Write-Host "  - $err"
            }
            Add-BlockedTask -Reason "Phase transition blocked: $currentPhase -> $targetPhase" -Category "waiting_dependency" -Severity "P1" -Phase $targetPhase
            Record-PhaseTransition -From $currentPhase -To $targetPhase -Type "blocked" -Reason ($errors -join "; ")
            Update-WorkflowMetrics -Action "validation_failed" -Phase $targetPhase
            exit 1
        }

        $phaseState = Get-JsonState -FilePath $phaseFile -Default @{ started_at = "" }
        if ($phaseState.started_at) {
            try {
                $started = [DateTime]::Parse($phaseState.started_at)
                $duration = (Get-Date) - $started
                Update-WorkflowMetrics -Action "phase_duration" -Phase $currentPhase -Details @{ duration_seconds = $duration.TotalSeconds }
            } catch {}
        }

        Set-CurrentPhase -phase $targetPhase
        Record-PhaseTransition -From $currentPhase -To $targetPhase -Type "forward"
        Update-WorkflowMetrics -Action "transition" -Details @{ from = $currentPhase; to = $targetPhase }
        Write-Log "Phase advanced: $currentPhase -> $targetPhase"
        Write-Host "Phase advanced: $currentPhase -> $targetPhase"
        Write-Host "Now in: $($phaseLabels[$targetPhase])"

        if ($targetPhase -eq "release") {
            $deployDecision = Get-DeploymentDecision
            Write-Host ""
            Write-Host "Deployment Decision: $($deployDecision.Decision)"
            if ($deployDecision.Reasons.Count -gt 0) {
                Write-Host "Reasons:"
                foreach ($r in $deployDecision.Reasons) { Write-Host "  - $r" }
            }
            if ($deployDecision.Decision -eq "DEPLOY_WITH_MONITORING") {
                Write-Host ""
                Write-Host "WARNING: Deploying with monitoring. Extra observability recommended."
            }
        }

    } elseif ($subCommand -eq "back") {
        $targetPhase = if ($args.Length -ge 3) { [string]$args[2] } else { "" }
        $reason = if ($args.Length -ge 4) { $args[3..($args.Length-1)] -join " " } else { "Feedback loop" }
        if ($targetPhase -eq "") {
            Write-Host "Usage: agent phase back <phase> [reason]"
            Write-Host "Use this to go back to a previous phase (feedback loop)"
            exit 1
        }

        $currentPhase = Get-CurrentPhase
        $allowed = $phaseTransitions[$currentPhase]

        if ($allowed -notcontains $targetPhase) {
            Write-Log "BLOCKED: Cannot go back from '$currentPhase' to '$targetPhase'" "ERROR"
            Write-Host "BLOCKED: Transition from '$currentPhase' to '$targetPhase' is not allowed."
            Write-Host "Allowed transitions from '$currentPhase': $($allowed -join ', ')"
            exit 1
        }

        Set-CurrentPhase -phase $targetPhase
        Record-PhaseTransition -From $currentPhase -To $targetPhase -Type "feedback" -Reason $reason
        Update-WorkflowMetrics -Action "feedback" -Details @{ from = $currentPhase; to = $targetPhase }
        Write-Log "Phase reverted: $currentPhase -> $targetPhase (feedback: $reason)" "WARNING"
        Write-Host "Phase reverted: $currentPhase -> $targetPhase (feedback loop)"
        Write-Host "Reason: $reason"
        Write-Host "Now in: $($phaseLabels[$targetPhase])"

    } else {
        Write-Host "Usage: agent phase <status|next|back> [phase] [reason]"
        Write-Host "  status   Show current phase"
        Write-Host "  next     Advance to next phase (with prerequisite validation)"
        Write-Host "  back     Go back to a previous phase (feedback loop)"
    }

} elseif ($command -eq "validate") {
    $targetPhase = if ($args.Length -ge 2) { [string]$args[1] } else { "" }
    if ($targetPhase -eq "") {
        Write-Host "Usage: agent validate <phase>"
        Write-Host "Validates prerequisites for the specified phase."
        Write-Host ""
        Write-Host "Available phases: $($validPhases -join ', ')"
        exit 1
    }

    if ($validPhases -notcontains $targetPhase) {
        Write-Host "Unknown phase: $targetPhase"
        Write-Host "Available phases: $($validPhases -join ', ')"
        exit 1
    }

    $errors = Test-PhasePrerequisites -targetPhase $targetPhase
    if ($errors.Count -eq 0) {
        Write-Host "PASS: All prerequisites met for '$targetPhase'"
        if ($targetPhase -eq "release") {
            $deployDecision = Get-DeploymentDecision
            Write-Host "Deployment Decision: $($deployDecision.Decision)"
            if ($deployDecision.Reasons.Count -gt 0) {
                foreach ($r in $deployDecision.Reasons) { Write-Host "  - $r" }
            }
        }
        Write-Host "You can advance to this phase with: agent phase next $targetPhase"
    } else {
        Write-Host "BLOCKED: Prerequisites not met for '$targetPhase':"
        foreach ($err in $errors) {
            Write-Host "  - $err"
        }
        exit 1
    }

} elseif ($command -eq "risk") {
    $subCommand = if ($args.Length -ge 2) { [string]$args[1] } else { "" }

    if ($subCommand -eq "add") {
        $severity = if ($args.Length -ge 3) { [string]$args[2] } else { "" }
        $description = if ($args.Length -ge 4) { $args[3..($args.Length-1)] -join " " } else { "" }
        if ($severity -eq "" -or $description -eq "") {
            Write-Host "Usage: agent risk add <critical|high|medium|low> <description>"
            exit 1
        }
        if (@("critical", "high", "medium", "low") -notcontains $severity) {
            Write-Host "Invalid severity: $severity. Use: critical, high, medium, low"
            exit 1
        }
        $risk = Add-Risk -Description $description -Severity $severity
        Write-Host "Risk registered: $($risk.id) [$severity] $description"

    } elseif ($subCommand -eq "resolve") {
        $riskId = if ($args.Length -ge 3) { [string]$args[2] } else { "" }
        if ($riskId -eq "") {
            Write-Host "Usage: agent risk resolve <risk-id>"
            exit 1
        }
        Resolve-Risk -RiskId $riskId
        Write-Host "Risk resolved: $riskId"

    } elseif ($subCommand -eq "list") {
        $state = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); total = 0; by_severity = @{ critical = @(); high = @(); medium = @(); low = @() }; mitigation_required = @() }
        Write-Host "=== Risk Registry ==="
        Write-Host "Total: $($state.total) risks"
        Write-Host ""
        if ($state.risks.Count -eq 0) {
            Write-Host "  No risks registered."
        } else {
            foreach ($risk in $state.risks) {
                $status = if ($risk.status -eq "open") { "OPEN" } else { "RESOLVED" }
                Write-Host "  [$($risk.severity.ToUpper())] [$status] $($risk.id): $($risk.description)"
                if ($risk.status -eq "resolved") { Write-Host "    Resolved: $($risk.resolved_at)" }
            }
        }
        Write-Host ""
        $openCritical = @($state.risks | Where-Object { $_.severity -eq "critical" -and $_.status -eq "open" }).Count
        $openHigh = @($state.risks | Where-Object { $_.severity -eq "high" -and $_.status -eq "open" }).Count
        if ($openCritical -gt 0 -or $openHigh -gt 0) {
            Write-Host "WARNING: $openCritical critical + $openHigh high risks are open."
            Write-Host "These will BLOCK execution/validation/release phases."
        }

    } else {
        Write-Host "Usage: agent risk <add|resolve|list>"
        Write-Host "  add <sev> <desc>    Register a risk (sev: critical/high/medium/low)"
        Write-Host "  resolve <id>        Resolve a risk"
        Write-Host "  list                List all risks"
    }

} elseif ($command -eq "block") {
    if ($args.Length -lt 2) {
        Write-Host "Usage: agent block <reason>"
        exit 1
    }
    $reason = $args[1..($args.Length-1)] -join " "
    $task = Add-BlockedTask -Reason $reason -Category "manual_review_required" -Severity "P1"
    Write-Host "Phase blocked: $($task.id)"
    Write-Host "Reason: $reason"
    Write-Host "Unblock with: agent unblock $($task.id)"

} elseif ($command -eq "unblock") {
    $taskId = if ($args.Length -ge 2) { [string]$args[1] } else { "" }
    if ($taskId -eq "") {
        Write-Host "Usage: agent unblock <task-id>"
        Write-Host "Use 'agent blocked' to see blocked task IDs"
        exit 1
    }
    Remove-BlockedTask -TaskId $taskId
    Write-Host "Task unblocked: $taskId"

} elseif ($command -eq "blocked") {
    $state = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @(); total = 0 }
    Write-Host "=== Blocked Tasks ==="
    Write-Host "Total: $($state.total)"
    Write-Host ""
    if ($state.tasks.Count -eq 0) {
        Write-Host "  No blocked tasks."
    } else {
        foreach ($task in $state.tasks) {
            $status = if ($task.status -eq "blocked") { "BLOCKED" } else { "RESOLVED" }
            Write-Host "  [$($task.severity)] [$status] $($task.id): $($task.reason)"
            Write-Host "    Phase: $($task.phase) | Category: $($task.category) | Created: $($task.created_at)"
        }
    }

} elseif ($command -eq "repair") {
    $subCommand = if ($args.Length -ge 2) { [string]$args[1] } else { "" }

    if ($subCommand -eq "start") {
        $currentPhase = Get-CurrentPhase
        if ($currentPhase -ne "validation" -and $currentPhase -ne "repair") {
            Write-Host "ERROR: Repair can only be started from validation or repair phase. Current: $currentPhase"
            exit 1
        }
        if ($currentPhase -eq "validation") {
            $allowed = $phaseTransitions["validation"]
            if ($allowed -notcontains "repair") {
                Write-Host "ERROR: Repair transition not allowed from current state"
                exit 1
            }
            Set-CurrentPhase -phase "repair" -skill "REPAIR_ORCHESTRATOR"
            Record-PhaseTransition -From "validation" -To "repair" -Type "feedback" -Reason "QA issues require repair"
            Update-WorkflowMetrics -Action "feedback" -Details @{ from = "validation"; to = "repair" }
            Write-Log "Repair cycle started from validation phase"
            Write-Host "Repair cycle started. Phase: Layer 3.5 - Repair & Recovery"
            Write-Host "Generate REPAIR_PLAN.md before applying fixes."
            Write-Host "Track retries with: agent retry status"
        } else {
            Write-Host "Already in repair phase. Continue with repair or use 'agent phase back execution' to apply fixes."
        }

    } elseif ($subCommand -eq "complete") {
        $currentPhase = Get-CurrentPhase
        if ($currentPhase -ne "repair") {
            Write-Host "ERROR: Not in repair phase. Current: $currentPhase"
            exit 1
        }
        if (-not (Test-Path "$docsDir\REPAIR_PLAN.md")) {
            Write-Host "WARNING: REPAIR_PLAN.md not found. Generate it before completing repair."
        }
        if (-not (Test-Path "$docsDir\REGRESSION_REPORT.md")) {
            Write-Host "WARNING: REGRESSION_REPORT.md not found. Run regression validation."
        }
        $budget = Get-RetryBudget
        $retryEntry = Add-RetryAttempt -Severity "P1" -Description "Repair cycle completed" -Result "success"
        Write-Log "Repair cycle completed"
        Write-Host "Repair cycle completed. Retry budget: $($budget.total_retries)/$($budget.max_total)"
        Write-Host "Next: agent phase next validation (re-validate) or agent phase next execution (apply more fixes)"

    } elseif ($subCommand -eq "fail") {
        $severity = if ($args.Length -ge 3) { [string]$args[2] } else { "P1" }
        $description = if ($args.Length -ge 4) { $args[3..($args.Length-1)] -join " " } else { "Repair attempt failed" }
        $retryResult = Add-RetryAttempt -Severity $severity -Description $description -Result "failed"
        Write-Host "Repair attempt recorded as FAILED."
        Write-Host "Retry budget: $($retryResult.budget.total_retries)/$($retryResult.budget.max_total)"
        if ($retryResult.escalation_needed) {
            Write-Host ""
            Write-Host "ESCALATION TRIGGERED: $($retryResult.escalation_reason)"
            Write-Host "Human intervention required. Check: agent risk list"
            Write-Host "Blocked tasks: agent blocked"
        } else {
            $sevKey = $severity.ToUpper()
            if ($retryResult.budget.by_severity.PSObject.Properties.Name -contains $sevKey) {
                $sevBudget = $retryResult.budget.by_severity.$sevKey
                Write-Host "$sevKey retries: $($sevBudget.current)/$($sevBudget.max)"
            }
        }

    } elseif ($subCommand -eq "status") {
        $budget = Get-RetryBudget
        Write-Host "=== Repair & Retry Status ==="
        Write-Host ""
        Write-Host "Total Retries: $($budget.total_retries)/$($budget.max_total)"
        Write-Host "Consecutive Failures: $($budget.consecutive_failures)"
        Write-Host ""
        Write-Host "Retry Budget by Severity:"
        foreach ($sev in @("P0", "P1", "P2", "P3")) {
            if ($budget.by_severity.PSObject.Properties.Name -contains $sev) {
                $sb = $budget.by_severity.$sev
                $esc = if ($sb.escalated) { " [ESCALATED]" } else { "" }
                Write-Host "  $sev`: $($sb.current)/$($sb.max)$esc"
            }
        }
        if ($budget.last_escalation) {
            Write-Host ""
            Write-Host "Last Escalation: $($budget.last_escalation)"
        }
        if ($budget.history.Count -gt 0) {
            Write-Host ""
            Write-Host "Recent Retry History (last 5):"
            $recent = $budget.history | Select-Object -Last 5
            foreach ($h in $recent) {
                $marker = if ($h.result -eq "failed") { "FAIL" } else { "PASS" }
                Write-Host "  [$marker] $($h.timestamp) $($h.severity): $($h.description)"
            }
        }

    } else {
        Write-Host "Usage: agent repair <start|complete|fail|status>"
        Write-Host "  start             Start a repair cycle (from validation phase)"
        Write-Host "  complete          Mark repair cycle as completed successfully"
        Write-Host "  fail <sev> [desc] Record a failed repair attempt"
        Write-Host "  status            Show repair and retry budget status"
    }

} elseif ($command -eq "regression") {
    $subCommand = if ($args.Length -ge 2) { [string]$args[1] } else { "" }

    if ($subCommand -eq "run") {
        Write-Host "=== Regression Validation ==="
        Write-Host ""
        $issues = @()
        if (Test-Path $projectDir) {
            $projectFiles = Get-ProjectCodeFiles
            if ($projectFiles.Count -eq 0) {
                $issues += "project/ directory is empty - no code to validate"
            }
        } else {
            $issues += "project/ directory not found"
        }
        if (-not (Test-Path "$docsDir\REPAIR_PLAN.md")) {
            $issues += "REPAIR_PLAN.md not found - generate before regression"
        }
        $riskState = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @() }
        $newCriticalRisks = @($riskState.risks | Where-Object { $_.severity -eq "critical" -and $_.status -eq "open" })
        if ($newCriticalRisks.Count -gt 0) {
            $issues += "$($newCriticalRisks.Count) critical risk(s) still open"
        }
        $blockedState = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @() }
        $activeBlocked = @($blockedState.tasks | Where-Object { $_.status -eq "blocked" })
        if ($activeBlocked.Count -gt 0) {
            $issues += "$($activeBlocked.Count) blocked task(s) still active"
        }
        if ($issues.Count -eq 0) {
            Write-Host "Regression Validation: PASS"
            Write-Host "  - Project code exists"
            Write-Host "  - Repair plan documented"
            Write-Host "  - No critical risks"
            Write-Host "  - No blocked tasks"
            Write-Host ""
            Write-Host "Generate docs/REGRESSION_REPORT.md with validation results."
        } else {
            Write-Host "Regression Validation: FAIL"
            foreach ($issue in $issues) {
                Write-Host "  - $issue"
            }
            Write-Host ""
            Write-Host "Resolve issues before completing repair."
            exit 1
        }

    } elseif ($subCommand -eq "status") {
        Write-Host "=== Regression Status ==="
        if (Test-Path "$docsDir\REGRESSION_REPORT.md") {
            Write-Host "REGRESSION_REPORT.md: Found"
            $report = Get-Content "$docsDir\REGRESSION_REPORT.md" -Raw
            if ($report -match "PASS|pass") {
                Write-Host "Status: PASS"
            } elseif ($report -match "FAIL|fail") {
                Write-Host "Status: FAIL"
            } else {
                Write-Host "Status: Review required"
            }
        } else {
            Write-Host "REGRESSION_REPORT.md: Not found"
            Write-Host "Run: agent regression run"
        }

    } else {
        Write-Host "Usage: agent regression <run|status>"
        Write-Host "  run     Execute regression validation checks"
        Write-Host "  status  Check regression report status"
    }

} elseif ($command -eq "retry") {
    $subCommand = if ($args.Length -ge 2) { [string]$args[1] } else { "" }

    if ($subCommand -eq "status") {
        $budget = Get-RetryBudget
        Write-Host "=== Retry Budget Status ==="
        Write-Host ""
        Write-Host "Total: $($budget.total_retries)/$($budget.max_total)"
        Write-Host "Consecutive Failures: $($budget.consecutive_failures)"
        Write-Host ""
        Write-Host "By Severity:"
        foreach ($sev in @("P0", "P1", "P2", "P3")) {
            if ($budget.by_severity.PSObject.Properties.Name -contains $sev) {
                $sb = $budget.by_severity.$sev
                $esc = if ($sb.escalated) { " [ESCALATED]" } else { "" }
                Write-Host "  $sev`: $($sb.current)/$($sb.max)$esc"
            }
        }

    } elseif ($subCommand -eq "reset") {
        Reset-RetryBudget
        Write-Host "Retry budget reset to defaults."

    } else {
        Write-Host "Usage: agent retry <status|reset>"
        Write-Host "  status  Show retry budget status"
        Write-Host "  reset   Reset retry budget to defaults"
    }

} elseif ($command -eq "escalation") {
    $subCommand = if ($args.Length -ge 2) { [string]$args[1] } else { "" }

    if ($subCommand -eq "check") {
        $budget = Get-RetryBudget
        $escalations = @()
        if ($budget.total_retries -ge $budget.max_total) {
            $escalations += "Total retry budget exceeded ($($budget.total_retries)/$($budget.max_total))"
        }
        if ($budget.consecutive_failures -ge 3) {
            $escalations += "Consecutive failures ($($budget.consecutive_failures))"
        }
        foreach ($sev in @("P0", "P1", "P2", "P3")) {
            if ($budget.by_severity.PSObject.Properties.Name -contains $sev) {
                $sb = $budget.by_severity.$sev
                if ($sb.escalated) {
                    $escalations += "$sev budget exceeded ($($sb.current)/$($sb.max))"
                }
            }
        }
        $riskState = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @() }
        $criticalRisks = @($riskState.risks | Where-Object { $_.severity -eq "critical" -and $_.status -eq "open" })
        if ($criticalRisks.Count -gt 0) {
            $escalations += "$($criticalRisks.Count) critical risk(s) open"
        }
        if ($escalations.Count -eq 0) {
            Write-Host "Escalation Check: No escalations pending."
        } else {
            Write-Host "Escalation Check: ACTIVE"
            foreach ($esc in $escalations) {
                Write-Host "  - $esc"
            }
        }

    } else {
        Write-Host "Usage: agent escalation check"
        Write-Host "  check   Check if any escalation conditions are met"
    }

} elseif ($command -eq "decision") {
    $deployDecision = Get-DeploymentDecision
    Write-Host "=== Deployment Decision ==="
    Write-Host "Decision: $($deployDecision.Decision)"
    if ($deployDecision.Reasons.Count -gt 0) {
        Write-Host "Reasons:"
        foreach ($r in $deployDecision.Reasons) { Write-Host "  - $r" }
    } else {
        Write-Host "No blocking issues found."
    }
    Write-Host ""
    Write-Host "Decision Levels:"
    Write-Host "  SAFE_TO_DEPLOY          - All checks passed"
    Write-Host "  DEPLOY_WITH_MONITORING  - Minor concerns, deploy with extra monitoring"
    Write-Host "  REQUIRES_REWORK         - Significant issues, rework required"
    Write-Host "  BLOCK_RELEASE           - Critical issues, release blocked"

} elseif ($command -eq "metrics") {
    $state = Get-JsonState -FilePath $metricsFile -Default @{ phase_durations = @{}; transition_counts = @{}; feedback_counts = @{}; validation_failures = @{}; total_phase_transitions = 0; total_feedback_loops = 0; created_at = ""; last_updated = "" }
    Write-Host "=== Workflow Metrics ==="
    Write-Host ""
    Write-Host "Tracking since: $($state.created_at)"
    Write-Host "Last updated:   $($state.last_updated)"
    Write-Host "Total transitions: $($state.total_phase_transitions)"
    Write-Host "Total feedback loops: $($state.total_feedback_loops)"
    Write-Host ""

    if ($state.phase_durations.PSObject.Properties.Name.Count -gt 0) {
        Write-Host "Phase Durations (avg seconds):"
        foreach ($prop in $state.phase_durations.PSObject.Properties) {
            Write-Host "  $($prop.Name): avg=$($prop.Value.avg_seconds)s (count=$($prop.Value.count))"
        }
        Write-Host ""
    }

    if ($state.transition_counts.PSObject.Properties.Name.Count -gt 0) {
        Write-Host "Transition Counts:"
        foreach ($prop in $state.transition_counts.PSObject.Properties) {
            Write-Host "  $($prop.Name): $($prop.Value)"
        }
        Write-Host ""
    }

    if ($state.feedback_counts.PSObject.Properties.Name.Count -gt 0) {
        Write-Host "Feedback Loop Counts:"
        foreach ($prop in $state.feedback_counts.PSObject.Properties) {
            Write-Host "  $($prop.Name): $($prop.Value)"
        }
        Write-Host ""
    }

    if ($state.validation_failures.PSObject.Properties.Name.Count -gt 0) {
        Write-Host "Validation Failures by Phase:"
        foreach ($prop in $state.validation_failures.PSObject.Properties) {
            Write-Host "  $($prop.Name): $($prop.Value) failures"
        }
        Write-Host ""
    }

    $execState = Get-JsonState -FilePath $executionStateFile -Default @{ statistics = @{ total_executions = 0; successful = 0; failed = 0; retried = 0 } }
    Write-Host "Execution Statistics:"
    Write-Host "  Total:  $($execState.statistics.total_executions)"
    Write-Host "  Success: $($execState.statistics.successful)"
    Write-Host "  Failed:  $($execState.statistics.failed)"
    Write-Host "  Retried: $($execState.statistics.retried)"

} elseif ($command -eq "status") {
    Write-Host "=== AI Engineering Workflow Status ==="
    Write-Host ""

    $currentPhase = Get-CurrentPhase
    Write-Host "Current Phase: $($phaseLabels[$currentPhase])"
    Write-Host ""

    Write-Host "Phase Checklist:"
    $phaseChecks = @(
        @{ Name = "idle"; Label = "Layer 0 - Idle"; File = "" },
        @{ Name = "understanding"; Label = "Layer 1 - Understanding"; File = "docs/REQUIREMENTS.md or docs/SYSTEM_UNDERSTANDING.md" },
        @{ Name = "alignment"; Label = "Layer 1.5 - Alignment"; File = "docs/PLANNING_ALIGNMENT_QUESTIONS.md" },
        @{ Name = "planning"; Label = "Layer 2 - Planning"; File = "docs/PROJECT_PLAN.md or docs/MODIFICATION_PLAN.md" },
        @{ Name = "execution"; Label = "Layer 3 - Execution"; File = "project/ (code)" },
        @{ Name = "validation"; Label = "Layer 4 - Validation"; File = "docs/QA_AUDIT_REPORT.md" },
        @{ Name = "repair"; Label = "Layer 3.5 - Repair & Recovery"; File = "docs/REPAIR_PLAN.md" },
        @{ Name = "release"; Label = "Layer 5 - Release"; File = "docs/RELEASE_EXECUTION_LOG.md" },
        @{ Name = "completed"; Label = "Completed"; File = "" }
    )

    foreach ($check in $phaseChecks) {
        $marker = if ($check.Name -eq $currentPhase) { ">>>" } else { "   " }
        $status = if ($check.Name -eq $currentPhase) { "[ACTIVE]" } else { "[     ]" }
        Write-Host "$marker $status $($check.Label)"
        if ($check.File) {
            $fileExists = $false
            if ($check.File -match " or ") {
                $parts = $check.File -split " or "
                foreach ($part in $parts) { if (Test-Path $part) { $fileExists = $true; break } }
            } elseif ($check.File -match " \(code\)") {
                $dir = $check.File -replace " \(code\)", ""
                if (Test-Path $dir) {
                    $files = @(Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne ".gitkeep" })
                    $fileExists = $files.Count -gt 0
                }
            } else {
                $fileExists = Test-Path $check.File
            }
            $fileStatus = if ($fileExists) { "OK" } else { "MISSING" }
            Write-Host "         Output: $($check.File) [$fileStatus]"
        }
    }

    Write-Host ""
    Write-Host "Allowed next: $($phaseTransitions[$currentPhase] -join ', ')"

    $riskState = Get-JsonState -FilePath $riskRegistryFile -Default @{ risks = @(); total = 0 }
    $openRisks = @($riskState.risks | Where-Object { $_.status -eq "open" })
    if ($openRisks.Count -gt 0) {
        Write-Host ""
        Write-Host "Open Risks: $($openRisks.Count)"
        foreach ($r in $openRisks) {
            Write-Host "  [$($r.severity.ToUpper())] $($r.id): $($r.description)"
        }
    }

    $blockedState = Get-JsonState -FilePath $blockedTasksFile -Default @{ tasks = @(); total = 0 }
    $activeBlocked = @($blockedState.tasks | Where-Object { $_.status -eq "blocked" })
    if ($activeBlocked.Count -gt 0) {
        Write-Host ""
        Write-Host "Blocked Tasks: $($activeBlocked.Count)"
        foreach ($b in $activeBlocked) {
            Write-Host "  [$($b.severity)] $($b.id): $($b.reason)"
        }
    }

    if (Test-Path $phaseFile) {
        $state = Get-Content $phaseFile -Raw | ConvertFrom-Json
        if ($state.last_updated) { Write-Host ""; Write-Host "Last updated: $($state.last_updated)" }
    }

} elseif ($command -eq "help") {
    Write-Host "Agent Tool v4.0 - AI Engineering Workflow Engine"
    Write-Host ""
    Write-Host "Usage: agent <command> [subcommand] [args]"
    Write-Host ""
    Write-Host "Workflow Commands:"
    Write-Host "  init                       Initialize project structure"
    Write-Host "  phase status               Show current workflow phase"
    Write-Host "  phase next [phase]         Advance to next phase (with validation)"
    Write-Host "  phase back [phase] [reason] Go back to a previous phase"
    Write-Host "  validate [phase]           Validate prerequisites for a phase"
    Write-Host "  status                     Show full workflow status overview"
    Write-Host ""
    Write-Host "Risk Management:"
    Write-Host "  risk add <sev> <desc>      Register a risk (sev: critical/high/medium/low)"
    Write-Host "  risk resolve <id>          Resolve a risk"
    Write-Host "  risk list                  List all risks"
    Write-Host ""
    Write-Host "Block Management:"
    Write-Host "  block <reason>             Block current phase with a reason"
    Write-Host "  unblock <id>               Unblock a blocked task"
    Write-Host "  blocked                    List all blocked tasks"
    Write-Host ""
    Write-Host "Repair & Recovery:"
    Write-Host "  repair start              Start a repair cycle (from validation phase)"
    Write-Host "  repair complete           Mark repair as completed successfully"
    Write-Host "  repair fail <sev> [desc]  Record a failed repair attempt"
    Write-Host "  repair status             Show repair and retry budget status"
    Write-Host "  regression run            Execute regression validation"
    Write-Host "  regression status         Check regression report status"
    Write-Host "  retry status              Show retry budget status"
    Write-Host "  retry reset               Reset retry budget to defaults"
    Write-Host "  escalation check          Check escalation conditions"
    Write-Host ""
    Write-Host "Decision & Metrics:"
    Write-Host "  decision                   Show deployment decision for current phase"
    Write-Host "  metrics                    Show workflow metrics"
    Write-Host ""
    Write-Host "Utilities:"
    Write-Host "  log <message>              Record an activity to the log"
    Write-Host "  unzip <file>               Extract compressed log files"
    Write-Host "  help                       Show this help message"
    Write-Host ""
    Write-Host "Workflow Phases:"
    Write-Host "  idle -> understanding -> alignment -> planning -> execution -> validation -> repair -> release -> completed"
    Write-Host ""
    Write-Host "Feedback Loops:"
    Write-Host "  validation -> execution    (fix code issues)"
    Write-Host "  validation -> planning     (plan adjustment needed)"
    Write-Host "  validation -> alignment    (business logic mismatch)"
    Write-Host "  validation -> repair       (QA issues require repair)"
    Write-Host "  repair     -> execution    (apply fixes)"
    Write-Host "  repair     -> validation   (re-validate after fix)"
    Write-Host "  repair     -> planning     (plan adjustment needed)"
    Write-Host "  repair     -> alignment    (requirements mismatch)"
    Write-Host "  execution  -> planning     (plan infeasible)"
    Write-Host "  execution  -> alignment    (hidden requirements found)"
    Write-Host "  release    -> execution    (deployment issues)"
    Write-Host ""
    Write-Host "Deployment Decisions:"
    Write-Host "  SAFE_TO_DEPLOY          - All checks passed"
    Write-Host "  DEPLOY_WITH_MONITORING  - Minor concerns, deploy with monitoring"
    Write-Host "  REQUIRES_REWORK         - Significant issues, rework required"
    Write-Host "  BLOCK_RELEASE           - Critical issues, release blocked"
    Write-Host ""
    Write-Host "Risk Severity Levels:"
    Write-Host "  critical  - Blocks execution/validation/release"
    Write-Host "  high      - Blocks release, requires rework"
    Write-Host "  medium    - Warning, proceed with caution"
    Write-Host "  low       - Informational, no blocking"

} elseif ($command -eq "log") {
    if ($args.Length -lt 2) {
        Write-Host "Usage: agent log <message>"
        exit 1
    }
    $message = $args[1..($args.Length-1)] -join " "
    Write-Log "$message"

} elseif ($command -eq "unzip") {
    if ($args.Length -lt 2) {
        Write-Host "Usage: agent unzip <zip_file_path>"
        exit 1
    }
    $zipFilePath = $args[1]
    if (-not (Test-Path $zipFilePath)) { Write-Log "Error: Zip file not found: $zipFilePath" "ERROR"; exit 1 }
    if ($zipFilePath -notlike "*.zip") { Write-Log "Error: File is not a zip file: $zipFilePath" "ERROR"; exit 1 }
    $extractPath = Split-Path -Path $zipFilePath -Parent
    try {
        $success = Expand-File -SourcePath $zipFilePath -DestinationPath $extractPath
        if ($success) { Write-Log "Extracted: $zipFilePath" } else { Write-Log "Error extracting zip file" "ERROR"; exit 1 }
    } catch { Write-Log "Error: $($_.Exception.Message)" "ERROR"; exit 1 }

} else {
    Write-Log "Error: Unknown command '$command'" "ERROR"
    Write-Host "Available commands: init, phase, validate, status, risk, block, unblock, blocked, repair, regression, retry, escalation, decision, metrics, log, unzip, help"
}
