# Examples

Real assets from a production use of Agent Tool, published as reference implementations.

These are not toy samples written to accompany the README. They are the actual files used on live
projects, with machine-specific paths replaced by placeholders.

| Path | What it demonstrates |
|---|---|
| `skills/binary-reverse/` | A non-trivial **skill** — a routing decision tree, not a tool list |
| `rules/security-policy.md` | A **rule file** that is prescriptive rather than boilerplate |
| `roles/agent-roles.md` | **Role-scoped dispatch** — six specialists with distinct mandates and tools |

---

## `skills/binary-reverse/`

A reverse engineering workflow that identifies a target binary and then routes it to the correct
decompiler. Covers PE / ELF / Mach-O across .NET, Python packers, Go, Rust, C/C++ and Delphi.

**Why it is a good example of a skill:** the hard part of reverse engineering is not running a
decompiler, it is knowing *which* of six to reach for given an unknown input. The skill encodes that
decision as a flowchart and a set of routing tables. A skill that simply listed tools would be far
less useful.

Used with `$RE_TOOLS` as the toolchain root. Replace it with your own install path.

---

## `rules/security-policy.md`

A security policy intended to be loaded as a rule file, so that every code generation and review
pass is measured against it. Ten sections: objectives, responsibility split, secure coding standard,
security testing, incident response, configuration hardening, audit cadence, training, compliance,
standing practices.

**Why it is a good example of a rule file:** §3.2 contains an enforcement note that reads —

> Authentication must be *verifiably* enforced at the request boundary. A configured environment
> variable, a log line saying `auth required`, or a middleware that is registered but never reached
> does not constitute enforcement.

That note exists because an agent once wrote exactly that bug: a middleware that logged
`auth required` and then let every request through. A generic policy would not name the failure mode.
This one does, because it was written after the fact.

There is also a credential rule in §5 — a credential committed to a repository is compromised, so
**rotate it rather than deleting the file**. History is not a security boundary.

---

## `roles/agent-roles.md`

Six role definitions — architect, security, backend-dev, frontend-dev, tester, devops — each
declaring expertise, capabilities, permitted tools, coordination channels and a performance
envelope.

**Why it is a good example of role scoping:** `security` and `tester` are configured at `medium`
response time while every implementation role is `fast`. The roles whose job is to find problems are
explicitly permitted to take longer, which removes the incentive to rubber-stamp. A single
general-purpose agent reviewing a change has no equivalent structural pressure.

Roles also broadcast on separate channels — general progress to `project-updates`, security findings
to `security-updates` — so security findings do not get buried in build chatter.

---

## Using these

Copy what you need into your project after `agent init`:

```bash
agent init
cp -r examples/skills/binary-reverse .agents/skills/
cp examples/rules/security-policy.md .agents/rules/
```

Then reference them from the generated `AGENTS.md` so the orchestrator loads them during the
appropriate phase.
