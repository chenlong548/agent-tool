# AI Engineering Workflow Enforcement Rules

This project uses a 7-layer AI engineering architecture with programmatic workflow enforcement. Read `AGENTS.md` for the complete workflow.

## Mandatory Phase Checks

1. Before writing code to `project/`, run `agent phase status`.
   The current phase must be `execution`, `validation`, or `repair`.

2. Before creating `docs/PROJECT_PLAN.md`, run `agent validate planning`.
   Planning must remain blocked until human confirmation artifacts are complete.

3. Before advancing to another phase, run `agent phase next <phase>`.
   Do not proceed when the command reports `BLOCKED`.

4. Before release, run `agent decision`.
   Do not deploy when the decision is `BLOCK_RELEASE` or `REQUIRES_REWORK`.

5. When risks are discovered, run `agent risk add <severity> <description>`.
   Critical and high risks must be resolved before execution, validation, or release.

6. When manual review is needed, run `agent block <reason>`.

## Prohibited Actions

- Do not skip workflow phases.
- Do not write implementation code before planning is complete.
- Do not generate a project plan without human confirmation.
- Do not ignore blocked transitions.
- Do not assume architecture, stack, deployment, or AI provider choices without confirmation.
- Do not modify files in `.agents/skills/` inside an initialized target project.

## Workflow Phases

```text
idle -> understanding -> alignment -> planning -> execution -> validation -> repair -> release -> completed
```

## Key Commands

| Command | Purpose |
|---|---|
| `agent phase status` | Check current phase |
| `agent phase next <phase>` | Advance phase with validation |
| `agent phase back <phase> [reason]` | Return to an upstream phase |
| `agent validate <phase>` | Check phase prerequisites |
| `agent repair start` | Enter repair workflow after QA findings |
| `agent regression run` | Validate after repair |
| `agent retry status` | Check repair retry budget |
| `agent risk add <sev> <desc>` | Register a risk |
| `agent block <reason>` | Block current phase |
| `agent decision` | Check deployment readiness |
| `agent status` | Show full workflow overview |

## Communication

All user-facing conversation must be in Chinese. Skill files and generated documents remain in English unless the user asks otherwise.
