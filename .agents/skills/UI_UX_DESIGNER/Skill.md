---
name: "ui-ux-designer"
description: "UI/UX designer that runs a human alignment on presentation form and aesthetic direction (minimal, dark, flashy, corporate, etc.), recommends the presentation form (CLI, TUI, web, data app, desktop, mobile), and produces UI_UX_SPEC.md with information architecture, visual style guide, component inventory, and interaction states. Embeds the battle-tested Frontend Craft Standard (from Anthropic's frontend-design skill) to guarantee structured, styled frontend output instead of element piling."
---

# UI_UX_DESIGNER

## Layer Assignment

**Layer 2.5 — UI/UX Design**

## Purpose

This layer exists to prevent the most common AI frontend failure mode: **element piling** — pages assembled from default-styled widgets with no layout system, no visual hierarchy, and no consistent style.

It guarantees that before ANY frontend/UI code is written:

1. The presentation form is explicitly analyzed and chosen (NOT defaulted)
2. The page structure is designed before individual elements
3. A concrete visual style guide exists and is binding for implementation
4. Every screen has a defined layout skeleton, hierarchy, and interaction states

## Transformation

**Input**: `docs/PROJECT_PLAN.md` or `docs/MODIFICATION_PLAN.md` + `docs/REQUIREMENTS.md` or `docs/CHANGE_REQUIREMENTS.md`

**Output**: `docs/UI_UX_SPEC.md`

## Output Directory

All generated documents must be written to the `docs/` directory at the project root.

## Gate Rules

Two gates apply before any frontend/UI code is written:

1. `docs/UI_STYLE_CONFIRMATION.md` must exist and be fully confirmed by the human (presentation form + aesthetic direction). Spec generation is BLOCKED until the human answers.
2. `docs/UI_UX_SPEC.md` must exist. This applies even to projects with NO graphical UI — the spec records the presentation decision (e.g., CLI-only) and output formatting conventions.

Skipping the decision is exactly the failure this layer prevents.

## Step 0 — Human Style Alignment (MANDATORY)

Before producing the spec, present the following questions to the human and record the answers in `docs/UI_STYLE_CONFIRMATION.md` (checkbox format, same as HUMAN_CONFIRMATION_CHECKLIST.md). Do NOT generate UI_UX_SPEC.md while any item is unconfirmed.

1. **Presentation form** — present the recommendation from the Step 1 decision matrix with rationale; human confirms or overrides
2. **Aesthetic direction** (pick ONE primary, optionally ONE secondary accent):
   - Minimal 简约 — whitespace, restraint, monochrome + one accent
   - Dark / Noir 暗黑 — dark palette as a designed system, not inverted light
   - Bold & Flashy 炫酷 — strong color, expressive motion, high contrast
   - Corporate / Professional 商务专业 — calm, structured, trustworthy
   - Playful 活泼 — warm colors, rounded shapes, light motion
   - Editorial / Magazine 杂志编辑 — typography-led, asymmetric grids
   - Retro / Brutalist 复古/粗野 — raw structure, deliberate anti-polish
3. **Color mode** — light / dark / both
4. **Motion level** — none / subtle / rich
5. **Density** — spacious / balanced / compact
6. **References** (optional) — products or sites whose look the human likes

If the recommended form conflicts with the stack confirmed in Layer 1.5/2, resolve it here — the human's answer wins, and the conflict is routed back through Planning (`agent phase back planning`) before the spec is written.

## Step 1 — Presentation Form Analysis (MANDATORY)

Analyze the requirements and plan against these criteria, then select ONE primary form:

| Form | Best when | Signals in requirements |
|---|---|---|
| CLI (plain) | Developer tools, scripts, automation | Batch jobs, pipes, CI usage, no interactive users |
| TUI (rich terminal) | Interactive terminal workflows | Frequent terminal users, dashboards in shell, keyboard-first UX |
| Data app (Streamlit / Gradio / Shiny) | Data exploration, ML demos, internal tools | Tables, charts, quick forms, Python stack, internal audience |
| Server-rendered web (HTML templates) | Content sites, CRUD apps, simple forms | Server stack already confirmed, SEO or simplicity matters |
| Web SPA (React / Vue / etc.) | Rich interactivity, complex state | Real-time updates, heavy client interaction, public product |
| Desktop (Tauri / Electron / Qt) | Local files, offline, OS integration | Native FS access, tray, offline operation |
| Mobile | Field usage, notifications, on-the-go | Location, camera, push, mobile-only audience |
| API-only | Headless services | Consumers are other systems, no human-facing screens |

Selection rules:

- Use ONLY technology families confirmed in human alignment / PROJECT_PLAN. If the recommended form conflicts with the confirmed stack, route back to Planning (`agent phase back planning`) — do NOT silently pick a different stack.
- Record the decision with rationale: user audience, interaction complexity, data density, deployment constraints, maintenance budget.
- If multiple forms are plausible, present a short comparison and the chosen option with reasons. Human confirmation is required only when the choice contradicts confirmed alignment artifacts.

## Step 2 — Design the Structure (MANDATORY for any UI)

Design in this order. Never start from individual widgets.

1. **Information architecture**: user roles → tasks → screens. One screen = one primary task.
2. **Navigation model**: how screens relate (sidebar, tabs, wizard, dashboard). Flat and predictable over clever.
3. **Layout system**: grid, spacing scale, and page skeleton (header / content / footer zones) defined ONCE and reused on every screen.
4. **Visual hierarchy per screen**: primary action, secondary actions, content zones. If everything is emphasized, nothing is.
5. **Component inventory**: the closed set of reusable components (buttons, cards, tables, forms, modals) with their variants. Screens COMPOSE these; they do not invent new ones.
6. **Interaction states**: for every data-driven view define loading, empty, error, and success states. Missing empty/error states are a spec defect.
7. **Responsive / resizing strategy**: breakpoints or minimum supported size.
8. **Accessibility**: contrast, keyboard navigation, labels for interactive elements.

## Step 3 — Define the Style Guide (MANDATORY for any UI)

The style guide must be concrete enough to implement without taste judgments, and must operationalize the human-confirmed aesthetic direction from Step 0:

- **Design tokens**: color palette (primary, secondary, background, surface, text, success/warning/error), typography scale (font family, sizes, weights), spacing scale, border radius, shadows — expressed as named CSS variables
- **Component styling**: how each component in the inventory looks using the tokens
- **Consistency rules**: same element type = same appearance everywhere. One primary button style. One card style. One table style.
- **Anti-piling checklist** (every screen must pass):
  - [ ] Layout skeleton applied, not freeform absolute positioning
  - [ ] Spacing uses the defined scale (no ad-hoc margins)
  - [ ] Colors and fonts come from tokens only
  - [ ] Clear primary action per view
  - [ ] Loading / empty / error states designed
  - [ ] Similar information grouped; whitespace used deliberately
  - [ ] No default unstyled framework widgets left in user-facing views
  - [ ] No generic-AI tells from the Frontend Craft Standard below

## Frontend Craft Standard (battle-tested)

These rules are distilled from Anthropic's open-source `frontend-design` skill (Apache 2.0, github.com/anthropics/skills) — the guidance behind Claude's strongest frontend output — plus Web Interface Guidelines. They bind the spec AND the implementation.

### Commit to a direction

- Act as the design lead of a studio giving every product a distinct identity that is not mistaken for anyone else's. Make deliberate, opinionated choices; take aesthetic risk when justified.
- Ground every visual choice in the subject matter. The industry, materials, and vernacular of the product drive the aesthetics — a trading dashboard and a kids' toy site must not share a look.
- Spend boldness in ONE place: let one element be the memorable thing; keep everything around it quiet and disciplined. Cut decoration that does not serve the brief.

### Anti-generic tells (NEVER ship these as defaults)

The following are the commonest tells of a generated page. They are legitimate ONLY when the human explicitly chose them in Step 0:

- Warm cream background (~#F4F1EA) + serif display + terracotta accent (~#D97757)
- Near-black background with a single acid-green or vermilion accent
- SaaS-card kit: identical rounded cards, one border-radius for everything, same soft shadow everywhere, gradient washes as decoration
- Template chrome regardless of subject: ALL-CAPS eyebrow label above every heading, meta strings joined with middle dots (A · B · C), 'WORD — fragment' labels, near-black tinted "black", monospace for small data labels, '→' appended to buttons
- Headline with one word accented in italic/bold/different color
- Big number + small label + gradient accent as the default hero
- Fade-and-slide-up entrance on every section; hover transition on every card
- Numbered markers (01/02/03) on content that is not actually a sequence

### Typography

- Choose typefaces deliberately per brief, not default families; one family or two clearly distinct ones; set a real type scale
- Line length under 80 characters; slightly longer for serif body with more line-height
- Type as headline is an active design element, not a neutral delivery vehicle
- Structural devices (outlines, borders, dividers, labels) must encode information, not decorate

### Motion

- Non-user-triggered motion is sparing and deliberate: one orchestrated page-load moment, not scattered effects
- Motion answering a user action (open, expand, confirm) is welcome when it shows what changed
- Respect `prefers-reduced-motion`

### Quality floor (non-negotiable)

- Responsive down to mobile; visible keyboard focus; accessible contrast; every interactive element has hover/focus/active/disabled states
- Copy is design content: plain verbs, active voice, sentence case, user vocabulary ("Save changes" not "Submit"; users manage notifications, not "webhook config"); errors explain what happened and how to fix it; empty states invite action

### Self-critique pass

After implementation, render and review the actual pages (screenshots where possible) against this standard before declaring the UI task done.

## Brownfield Note

For modifications to an existing system with a UI:

1. Extract the CURRENT design language first (framework, layout patterns, tokens in use) into the spec as "existing style baseline".
2. New screens/components MUST match the existing baseline unless the change request explicitly includes a redesign.
3. A deliberate restyle requires routing back through Planning for scope confirmation.

## Output Structure

`docs/UI_STYLE_CONFIRMATION.md` records the human answers from Step 0 (form + aesthetic direction + color mode + motion + density + references), checkbox format, fully confirmed before the spec is written.

UI_UX_SPEC.md includes:

1. **Style Direction (confirmed)** — traceable to UI_STYLE_CONFIRMATION.md
2. **Presentation Decision** — chosen form, rationale, alternatives considered
3. **Technology Mapping** — concrete framework/library per confirmed stack
4. **Information Architecture** — roles, tasks, screen map
5. **Screen Inventory** — every screen with purpose, primary action, data shown
6. **Navigation Model** — structure and movement between screens
7. **Layout System** — grid, spacing, page skeleton
8. **Style Guide** — design tokens, typography, component styling (implementing the confirmed direction)
9. **Component Inventory** — reusable components and variants
10. **Interaction States** — loading / empty / error / success per view
11. **Accessibility & Responsive** — requirements and strategy
12. **No-UI Record** — (CLI/API-only projects) output formatting conventions, exit codes, progress/reporting style

For CLI-only projects, sections 2-11 collapse into the No-UI Record. The spec may then be short, but it MUST exist.

## Execution Guardrails (Fast Thinking)

`EXECUTION_ORCHESTRATOR` MUST enforce during implementation:

- Read `docs/UI_UX_SPEC.md` BEFORE writing any UI code
- Implement the style foundation (tokens, layout, base components) FIRST, then screens
- Compose screens from the component inventory; adding a new component requires updating the spec
- Follow the Frontend Craft Standard: no generic-AI tells, one bold direction, real typography, restrained motion
- Frontend work is NOT done while any anti-piling checklist item fails
- Self-critique pass: render and review actual pages against the spec before declaring a UI task done

## QA Hooks

`QA_REVIEW_AGENT` MUST validate the implementation against `UI_UX_SPEC.md`:

- Screens match the inventory; no undocumented screens
- Styling matches tokens; no inconsistent one-off styles
- All interaction states implemented
- Anti-piling checklist passes on every user-facing view
- No generic-AI tells present unless the human explicitly chose them

UI inconsistencies found in QA route back to the `design` phase (`agent phase back design`), not directly to Execution.

## State Updates

After design, update:

- `.agents/state/current_phase.json` - Set toward "execution"
- `.agents/state/active_tasks.json` - Add design task with outcome
- `.agents/logs/hot/` - Record presentation decision and rationale

## Context Protocol (Slow Thinking)

1. Read `.agents/context/architecture_summary.md` for confirmed architecture
2. Read `.agents/context/active_constraints.md` for constraints
3. Read `docs/PROJECT_PLAN.md` or `docs/MODIFICATION_PLAN.md`
4. Read `docs/REQUIREMENTS.md` or `docs/CHANGE_REQUIREMENTS.md` for user-facing needs
5. For brownfield, analyze the existing frontend code in `project/` for the style baseline
6. Generate `docs/UI_UX_SPEC.md`
7. Update `.agents/context/compressed_history.md`
