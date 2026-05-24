#!/usr/bin/env bash
set -euo pipefail

COMMAND_NAME="agent"
TOOL_HOME="${AGENT_TOOL_HOME:-$HOME/.agent-tool}"
INSTALL_DIR="${AGENT_TOOL_BIN:-$HOME/.local/bin}"
SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

show_help() {
  cat <<'EOF'
Agent Tool v4.0 - AI Engineering Workflow Engine

Usage:
  installers/install.sh install

After installation:
  agent init
  agent help
EOF
}

install_tool() {
  if ! command -v pwsh >/dev/null 2>&1 && ! command -v powershell >/dev/null 2>&1; then
    echo "Agent Tool requires PowerShell 7+ (pwsh) or Windows PowerShell." >&2
    echo "Install PowerShell: https://learn.microsoft.com/powershell/" >&2
    exit 1
  fi

  echo "Installing Agent Tool v4.0..."
  mkdir -p "$TOOL_HOME" "$INSTALL_DIR"

  rm -rf "$TOOL_HOME/core" "$TOOL_HOME/.agents"
  cp -R "$SOURCE_ROOT/core" "$TOOL_HOME/core"
  cp -R "$SOURCE_ROOT/.agents" "$TOOL_HOME/.agents"
  cp "$SOURCE_ROOT/AGENTS.md" "$TOOL_HOME/AGENTS.md"
  chmod +x "$TOOL_HOME/core/agent.sh"

  ln -sf "$TOOL_HOME/core/agent.sh" "$INSTALL_DIR/$COMMAND_NAME"

  echo "Agent Tool v4.0 installed successfully."
  echo "Add $INSTALL_DIR to PATH if it is not already there."
  echo "Usage: $COMMAND_NAME init"
}

case "${1:-help}" in
  install) install_tool ;;
  help|-h|--help) show_help ;;
  *) show_help; exit 1 ;;
esac
