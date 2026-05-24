#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/agent.ps1" "$@"
fi

if command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/agent.ps1" "$@"
fi

echo "Agent Tool requires PowerShell 7+ (pwsh) or Windows PowerShell." >&2
echo "Install PowerShell: https://learn.microsoft.com/powershell/" >&2
exit 1
