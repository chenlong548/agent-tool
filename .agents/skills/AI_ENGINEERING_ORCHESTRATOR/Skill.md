---
name: "ai-engineering-orchestrator"
description: "Central orchestration skill for workflow execution, skill scheduling, phase progression, state management, risk escalation, repair coordination, and human-aligned planning enforcement."
---

# AI_ENGINEERING_ORCHESTRATOR

## Layer Assignment

Layer 6 - Orchestration

## Overview

This skill coordinates the full AI engineering workflow. It is responsible for selecting the correct layer, enforcing phase gates, preserving state, escalating risk, and ensuring that human alignment is complete before planning or implementation proceeds.

## Responsibilities

### Automated Workflow
- Select the correct workflow path
- Coordinate phase progression
- Enforce validation gates
- Route feedback loops

### Skill Scheduling
- Load the required skill before executing a layer
- Pass the right artifacts between layers
- Prevent downstream work when prerequisites are missing

### State Management
- Update `.agents/state/current_phase.json`
- Track execution history, risks, blockers, metrics, and retry budgets
- Keep `.agents/context/` aligned with durable decisions

### Human Alignment Enforcement
- Invoke `PLANNING_ALIGNMENT_AGENT` before project planning
- Block planning while ambiguity or unconfirmed assumptions remain
- Require human confirmation for architecture, stack, deployment, AI provider, and MVP scope

### Risk And Repair Coordination
- Register risks with `agent risk add`
- Block work when manual review is required
- Route QA failures to `REPAIR_ORCHESTRATOR` when self-repair is appropriate
- Escalate to humans when retry budgets or uncertainty thresholds are exceeded

## Skill Registry

Agent Tool v4.0 includes 12 skills across 7 layers:

- `ENGINEERING_MEMORY_MANAGER`
- `PRD_ANALYZER`
- `SOURCE_CODE_ANALYZER`
- `CHANGE_REQUIREMENTS_ANALYZER`
- `PLANNING_ALIGNMENT_AGENT`
- `PROJECT_PLANNER`
- `CHANGE_PLANNER`
- `EXECUTION_ORCHESTRATOR`
- `QA_REVIEW_AGENT`
- `REPAIR_ORCHESTRATOR`
- `RELEASE_ORCHESTRATOR`
- `AI_ENGINEERING_ORCHESTRATOR`

## Workflow Coordination

### Greenfield Projects

```text
PRD_ANALYZER
-> PLANNING_ALIGNMENT_AGENT
-> Human Confirmation
-> PROJECT_PLANNER
-> EXECUTION_ORCHESTRATOR
-> QA_REVIEW_AGENT
-> REPAIR_ORCHESTRATOR (when needed)
-> RELEASE_ORCHESTRATOR
```

### Brownfield Projects

```text
SOURCE_CODE_ANALYZER
-> CHANGE_REQUIREMENTS_ANALYZER
-> PLANNING_ALIGNMENT_AGENT (for high-impact changes)
-> Human Confirmation (when required)
-> CHANGE_PLANNER
-> EXECUTION_ORCHESTRATOR
-> QA_REVIEW_AGENT
-> REPAIR_ORCHESTRATOR (when needed)
-> RELEASE_ORCHESTRATOR
```

## Human Alignment Gate

For Greenfield work, the orchestrator MUST:

1. Complete `PRD_ANALYZER`
2. Invoke `PLANNING_ALIGNMENT_AGENT`
3. Present alignment questions to the human
4. Wait for all confirmation artifacts to be accepted
5. Allow `PROJECT_PLANNER` only after `HUMAN_CONFIRMATION_CHECKLIST.md` is complete
6. Block planning and escalate if ambiguity remains

## Required Commands

- `agent phase status` before major work
- `agent validate <phase>` before phase transitions
- `agent phase next <phase>` to advance
- `agent phase back <phase> [reason]` for feedback loops
- `agent risk add <severity> <description>` for identified risks
- `agent block <reason>` when manual review is needed
- `agent decision` before release

## Final Rule

Never treat the workflow as complete until state, documents, code, validation, risks, and release readiness are consistent.
