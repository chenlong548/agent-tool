---
name: "source-code-analyzer"
description: "Source code analyzer that transforms source code into SYSTEM_UNDERSTANDING.md with architecture recovery, dependency analysis, runtime flow, technical debt analysis, and risk analysis."
---

# SOURCE_CODE_ANALYZER

## Layer Assignment

**Layer 1 — Understanding**

## Transformation

**Input**: Source Code Repository

**Output**: `docs/SYSTEM_UNDERSTANDING.md`

## Output Directory

All generated documents must be written to the `docs/` directory at the project root.

## Responsibilities

### Architecture Recovery
- Identify system components
- Analyze module boundaries
- Reconstruct architecture views
- Map component relationships

### Dependency Analysis
- Identify dependency relationships
- Analyze dependency graphs
- Identify critical dependencies
- Detect circular dependencies
- Assess dependency health (outdated, vulnerable)

### Runtime Flow
- Trace execution paths
- Analyze data flow
- Identify bottleneck points
- Map API endpoints and handlers
- Analyze async patterns and queues

### Technical Debt Analysis
- Identify code smells
- Assess refactoring needs
- Prioritize debt items
- Estimate remediation effort

### Risk Analysis
- Identify security risks
- Assess stability risks
- Predict potential issues
- Evaluate test coverage gaps

## Output Structure

SYSTEM_UNDERSTANDING.md contains:

1. **System Overview** - Project structure overview, tech stack, and entry points
2. **Architecture Views** - Components, relationships, and module boundaries
3. **Dependency Graph** - Module dependency relationships and critical paths
4. **Runtime Analysis** - Execution flow, data flow, and API mapping
5. **Technical Debt Report** - Debt inventory, priorities, and remediation estimates
6. **Risk Assessment** - Risk identification, severity, and mitigation strategies
7. **Improvement Recommendations** - Optimization suggestions and refactoring priorities

## Analysis Techniques

- Static code analysis
- Dependency graph construction
- Complexity metrics
- Code clone detection
- Security vulnerability scanning
- Test coverage analysis

## Context Protocol (Slow Thinking)

1. Read `.agents/context/architecture_summary.md` for existing architecture knowledge
2. Read `.agents/context/active_constraints.md` for current constraints
3. Read `.agents/logs/cold/` for historical context
4. Analyze source code and generate `docs/SYSTEM_UNDERSTANDING.md`
5. Update `.agents/context/architecture_summary.md` with discovered architecture
6. Update `.agents/context/compressed_history.md`

## State Updates

After analysis, update:
- `.agents/state/current_phase.json` - Set to "change_ready"
- `.agents/state/active_tasks.json` - Add analysis task
- `.agents/state/risk_registry.json` - Register discovered risks

## Quality Gates

- Architecture coverage completeness
- Dependency graph accuracy
- Risk assessment thoroughness
- Technical debt prioritization validity
