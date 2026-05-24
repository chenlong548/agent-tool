---
name: "change-planner"
description: "Change planner that transforms SYSTEM_UNDERSTANDING and CHANGE_REQUIREMENTS into MODIFICATION_PLAN.md with safe modification planning, incremental evolution, rollback strategy, regression prevention, and human alignment for high-impact changes."
---

# CHANGE_PLANNER

## Layer Assignment

**Layer 2 — Planning**

## Transformation

**Input**:
- `docs/SYSTEM_UNDERSTANDING.md`
- `docs/CHANGE_REQUIREMENTS.md`
- Human-confirmed alignment artifacts (for high-impact changes)

**Output**: `docs/MODIFICATION_PLAN.md`

## Output Directory

All generated documents must be written to the `docs/` directory at the project root.

## Prerequisite: Human Alignment Gate (Conditional)

For **high-impact changes**, MODIFICATION_PLAN generation is BLOCKED until:

- `PLANNING_ALIGNMENT_QUESTIONS.md` has been answered by the human
- `HUMAN_CONFIRMATION_CHECKLIST.md` is fully signed off
- Architecture change alignment is confirmed
- Technology change alignment is confirmed
- Deployment change alignment is confirmed

### High-Impact Change Criteria

Human alignment is REQUIRED if the change involves:

- Architecture modification (e.g., monolith → microservice)
- Technology stack replacement (e.g., database migration)
- Deployment strategy change
- Breaking API changes
- Data schema migration
- AI provider or model change
- Security model modification

For **low-impact changes** (bug fixes, UI tweaks, configuration updates), human alignment is OPTIONAL.

## Prohibited Assumptions

The following assumptions are PROHIBITED without explicit human confirmation for high-impact changes:

- Architecture modification decisions
- Technology replacement decisions
- Data migration strategy
- Deployment change strategy
- Rollback strategy for critical systems

## Responsibilities

### Safe Modification Planning
- Design safe modification paths
- Minimize change impact
- Define modification boundaries
- Identify high-impact vs low-impact changes

### Incremental Evolution
- Phased implementation
- Gradual migration
- Continuous integration
- Backward compatibility preservation

### Rollback Strategy
- Design rollback plans for each phase
- Establish rollback procedures
- Validate rollback mechanisms
- Define rollback triggers

### Regression Prevention
- Design test coverage for modified code
- Establish validation strategy
- Set up quality gates
- Define regression test suites

### Impact Assessment
- Classify change severity (high/medium/low)
- Identify affected modules and dependencies
- Estimate effort and risk
- Define mitigation strategies

## Output Structure

MODIFICATION_PLAN.md includes:

1. **Change Classification** - High-impact vs low-impact categorization
2. **Modification Scope** - Code scope of changes and affected modules
3. **Impact Assessment** - Severity, risk, and effort estimation
4. **Implementation Plan** - Phased implementation steps
5. **Rollback Plan** - Rollback steps, triggers, and conditions
6. **Test Strategy** - Regression test plan and validation gates
7. **Migration Strategy** - Data migration and compatibility plan (if applicable)
8. **Alignment Traceability** - References to human-confirmed decisions (for high-impact changes)

## Change Principles

- Minimal intrusion principle
- Backward compatibility first
- Verifiability
- Rollback capability
- Incremental evolution
- Human alignment for high-impact changes

## Context Protocol (Slow Thinking)

1. Read `.agents/context/architecture_summary.md` for existing architecture
2. Read `.agents/context/active_constraints.md` for current constraints
3. Read `.agents/logs/cold/` for historical context
4. Read `docs/SYSTEM_UNDERSTANDING.md` and `docs/CHANGE_REQUIREMENTS.md`
5. Read alignment artifacts if available (for high-impact changes)
6. Generate `docs/MODIFICATION_PLAN.md`
7. Update `.agents/context/compressed_history.md`

## State Updates

After planning, update:
- `.agents/state/current_phase.json` - Set to "execution_ready"
- `.agents/state/active_tasks.json` - Add planning task
- `.agents/state/risk_registry.json` - Register identified risks

## Quality Gates

- Change classification completeness
- Impact assessment coverage
- Rollback plan feasibility
- Test strategy adequacy
- Alignment verification (for high-impact changes)
