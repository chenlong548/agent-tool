This repository contains Agent Tool v4.0.

For local workflow behavior, read `AGENTS.md`.
For generated project enforcement rules, read `.agents/rules/workflow_rules.md`.

Critical rules:
- Keep generated project templates deterministic and clean.
- Before changing CLI phase behavior, smoke test `agent init`.
- Do not publish local logs, sample execution state, or generated project output.
- Keep user-facing workflow conversation in Chinese when operating as the orchestrator.
