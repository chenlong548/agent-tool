# Changelog

## Unreleased

- Fixed: `Add-Risk` / `Add-BlockedTask` return values were not captured at three call sites, so a
  stray `System.Collections.Hashtable` was printed on screen and `Add-RetryAttempt` returned a
  3-element array instead of a single object when escalation triggered.
- Fixed: `agent phase next` registered a blocked task against the target phase whenever
  prerequisites were missing. Because the prerequisite check also counts blocked tasks targeting
  that phase, the gate could refuse to open even after every prerequisite had been satisfied, and
  each retry added another blocker. Prerequisite failures are now recorded in the phase transition
  log and workflow metrics only.
- Fixed: entity ids for blocked tasks, risks and transitions used second resolution, so two records
  created in the same second shared an id and `agent unblock` / `agent risk resolve` could clear
  more than one record. Ids now carry millisecond precision plus a per-process sequence.
- Fixed: `agent unblock <id>` and `agent risk resolve <id>` reported success for ids that did not
  exist. They now report that nothing matched and exit non-zero, so a typo cannot silently read as
  a resolved record.
- Fixed: `agent risk list` claimed that open high risks block execution, validation and release.
  Only critical risks block those phases; a high risk blocks release alone, by forcing the
  deployment decision to `REQUIRES_REWORK`. The warning now states each severity's real effect.
- Fixed: `agent phase back` accepted targets that are ordinary forward steps and recorded them as
  feedback loops, inflating the feedback-loop metric and mistyping the transition log. It now only
  accepts an earlier phase or a documented rework loop, and points at `phase next` otherwise.

## v4.0

- Added `REPAIR_ORCHESTRATOR` as Layer 3.5 for autonomous recovery and repair planning.
- Added retry budget tracking and escalation commands.
- Added regression validation commands.
- Added deployment decision support.
- Added workflow metrics and richer execution state tracking.
- Added generated rule files for multiple AI coding tools.
- Strengthened human alignment before planning.

## v3.0

- Added workflow engine commands for phase status, transition, validation, and status overview.
- Added programmatic phase validation and feedback loops.
- Added planning alignment into Brownfield workflows.

## v2.2

- Added `PLANNING_ALIGNMENT_AGENT`.
- Enforced human confirmation before planning.
- Standardized skill files in English.

## v2.1

- Added Slow/Fast Thinking architecture.
- Added `.agents/state/` and `.agents/context/`.

## v2.0

- Introduced layered skill architecture.
