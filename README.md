# Agent Tool v4.0

Agent Tool is a local AI engineering workflow engine. It initializes a project with an `AGENTS.md` orchestration entry point, 12 specialized skill files, workflow state, context memory, risk tracking, repair loops, and rule files for popular AI coding tools.

The goal is simple: make AI-assisted engineering less ad hoc by forcing clear phases, human-aligned planning, validation gates, and release decisions.

## What It Provides

- 7-layer AI engineering architecture
- 12 built-in skills
- Slow/Fast Thinking workflow separation
- Human alignment gate before planning
- Programmatic phase transitions
- Risk registry and blocked task tracking
- QA-to-repair feedback loop
- Retry budget and human escalation rules
- Regression and deployment decision commands
- Generated rule files for Codex, Claude Code, Cursor, TRAE, GitHub Copilot, Windsurf, Cline, and Aider

## Architecture

```text
Layer 6   AI_ENGINEERING_ORCHESTRATOR     Orchestration
Layer 5   RELEASE_ORCHESTRATOR            Release and production readiness
Layer 4   QA_REVIEW_AGENT                 Validation and product reality audit
Layer 3.5 REPAIR_ORCHESTRATOR             Repair, retry, regression protection
Layer 3   EXECUTION_ORCHESTRATOR          Implementation
Layer 2   PROJECT_PLANNER, CHANGE_PLANNER Planning
Layer 1.5 PLANNING_ALIGNMENT_AGENT        Human alignment
Layer 1   PRD_ANALYZER, SOURCE_CODE_ANALYZER,
          CHANGE_REQUIREMENTS_ANALYZER    Understanding
Layer 0   ENGINEERING_MEMORY_MANAGER      Memory and logs
```

## Workflows

### Greenfield

```text
PRD
  -> PRD_ANALYZER
  -> PLANNING_ALIGNMENT_AGENT
  -> Human Confirmation
  -> PROJECT_PLANNER
  -> EXECUTION_ORCHESTRATOR
  -> QA_REVIEW_AGENT
  -> REPAIR_ORCHESTRATOR (when needed)
  -> RELEASE_ORCHESTRATOR
```

### Brownfield

```text
Existing code + change request
  -> SOURCE_CODE_ANALYZER
  -> CHANGE_REQUIREMENTS_ANALYZER
  -> PLANNING_ALIGNMENT_AGENT (for high-impact changes)
  -> CHANGE_PLANNER
  -> EXECUTION_ORCHESTRATOR
  -> QA_REVIEW_AGENT
  -> REPAIR_ORCHESTRATOR (when needed)
  -> RELEASE_ORCHESTRATOR
```

## Installation

### Windows

```powershell
git clone https://github.com/chenlong548/agent-tool.git
cd agent-tool
.\installers\install.cmd install
```

If `%USERPROFILE%\bin` is not already in `PATH`, add it or run the CLI directly:

```powershell
& "C:\path\to\agent-tool\core\agent.ps1" help
```

### macOS / Linux

Install PowerShell 7+ first, then:

```bash
git clone https://github.com/chenlong548/agent-tool.git
cd agent-tool
./installers/install.sh install
```

If `~/.local/bin` is not already in `PATH`, add it or run the wrapper directly:

```bash
./core/agent.sh help
```

## Quick Start

In the project you want to manage:

```bash
agent init
agent status
agent phase next understanding
```

Then open the generated `AGENTS.md` with your AI coding tool. The orchestrator will ask which workflow to run and load the matching skills.

## Commands

| Command | Description |
|---|---|
| `agent init` | Initialize the current project |
| `agent phase status` | Show current phase and allowed transitions |
| `agent phase next <phase>` | Advance to a phase with prerequisite validation |
| `agent phase back <phase> [reason]` | Move back through a feedback loop |
| `agent validate <phase>` | Validate prerequisites for a phase |
| `agent status` | Show full workflow overview |
| `agent risk add <severity> <description>` | Register a risk |
| `agent risk resolve <id>` | Resolve a risk |
| `agent risk list` | List risks |
| `agent block <reason>` | Block current phase |
| `agent unblock <id>` | Resolve a blocked task |
| `agent blocked` | List blocked tasks |
| `agent repair start` | Start repair after QA findings |
| `agent repair complete` | Mark repair cycle complete |
| `agent repair fail <severity> [description]` | Record failed repair attempt |
| `agent regression run` | Run regression readiness checks |
| `agent retry status` | Show retry budget |
| `agent escalation check` | Check escalation conditions |
| `agent decision` | Show deployment decision |
| `agent metrics` | Show workflow metrics |
| `agent log <message>` | Record activity log |
| `agent unzip <file>` | Extract a zip file |
| `agent help` | Show help |

## Phase Model

```text
idle -> understanding -> alignment -> planning -> execution -> validation -> repair -> release -> completed
```

Supported feedback loops:

- `validation -> execution`
- `validation -> planning`
- `validation -> alignment`
- `validation -> repair`
- `repair -> execution`
- `repair -> validation`
- `repair -> planning`
- `repair -> alignment`
- `execution -> planning`
- `execution -> alignment`
- `release -> execution`

## Generated Project Structure

```text
your-project/
+-- .agents/
|   +-- skills/
|   +-- state/
|   +-- context/
|   +-- logs/
|   +-- rules/
+-- docs/
+-- project/
+-- AGENTS.md
+-- CLAUDE.md
+-- .cursorrules
+-- .trae/rules/project_rules.md
+-- .github/copilot-instructions.md
+-- .windsurfrules
+-- .clinerules
+-- .aider.conf.yml
```

## Design Principles

- Planning is blocked until human alignment is complete.
- Critical and high risks must be visible in state, not hidden in prose.
- QA validates product reality, not only code correctness.
- Repair must be root-cause driven and protected by retry budgets.
- Release requires a deployment decision, rollback thinking, and observability planning.
- Generated documents stay in `docs/`; implementation output stays in `project/`.

## Project Status

Agent Tool v4.0 is suitable for early open-source use as a local workflow engine and project initializer. It is intentionally lightweight: the CLI is implemented in PowerShell and the intelligence lives in the generated `AGENTS.md` plus skill files.

## License

MIT. See [LICENSE](LICENSE).
