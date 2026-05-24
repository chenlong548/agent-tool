# Contributing

Thanks for helping improve Agent Tool.

## Development Setup

1. Clone the repository.
2. Use PowerShell 7+ where possible.
3. Run the CLI directly during development:

```powershell
& .\core\agent.ps1 help
```

## Smoke Test

Before opening a pull request, run:

```powershell
$tmp = Join-Path $env:TEMP ("agent-tool-smoke-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
Push-Location $tmp
& "C:\path\to\agent-tool\core\agent.ps1" init
& "C:\path\to\agent-tool\core\agent.ps1" status
& "C:\path\to\agent-tool\core\agent.ps1" phase next understanding
Pop-Location
```

## Guidelines

- Keep skill files in English.
- Keep user-facing workflow instructions clear and direct.
- Do not add generated project artifacts as core source unless they are templates.
- Update `README.md` and `AGENTS.md` when changing phases, skills, or commands.
- Preserve the human alignment gate before planning.
- Add or update smoke tests when changing CLI behavior.

## Pull Request Checklist

- CLI help still works.
- `agent init` works in a clean directory.
- New files are documented.
- No local logs or generated sample project output are included accidentally.
