---
name: "prd-analyzer"
description: "PRD analyzer that transforms PRD documents into structured REQUIREMENTS.md with requirements analysis, implicit requirements inference, user flows, edge cases, and non-functional requirements."
---

# PRD_ANALYZER

## Layer Assignment

**Layer 1 — Understanding**

## Transformation

**Input**: PRD (Product Requirements Document)

**Output**: `docs/REQUIREMENTS.md`

## Output Directory

All generated documents must be written to the `docs/` directory at the project root.

## Responsibilities

### Requirements Analysis
- Extract core functional requirements
- Analyze business objectives
- Define user value

### Implicit Requirements Inference
- Infer unstated requirements
- Identify potential assumptions
- Discover hidden dependencies

### User Flows
- Analyze user journeys
- Define interaction patterns
- Identify critical paths

### Edge Cases
- Analyze abnormal scenarios
- Identify boundary conditions
- Handle extreme cases

### Non-Functional Requirements
- Performance requirements
- Security requirements
- Usability requirements
- Scalability requirements

## Output Structure

REQUIREMENTS.md contains:

1. **Executive Summary** - Project overview and objectives
2. **Functional Requirements** - Core feature list
3. **User Roles** - Role definitions and responsibilities
4. **User Stories** - User scenario descriptions
5. **Non-Functional Requirements** - Quality attributes
6. **Boundary Conditions** - Exception handling
7. **Acceptance Criteria** - Definition of done

## Context Protocol (Slow Thinking)

1. Read `.agents/context/architecture_summary.md` for existing architecture
2. Read `.agents/context/active_constraints.md` for current constraints
3. Read `.agents/logs/cold/` for historical context
4. Analyze PRD and generate `docs/REQUIREMENTS.md`
5. Update `.agents/context/compressed_history.md`

## State Updates

After analysis, update:
- `.agents/state/current_phase.json` - Set to "planning_ready"
- `.agents/state/active_tasks.json` - Add PRD analysis task

## Quality Gates

- Requirements completeness check
- Conflict detection
- Consistency verification
- Testability assessment
