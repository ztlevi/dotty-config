alias kk="kiro-cli --v3 --tui"
alias kiro-enable-checkpoint="kiro-cli settings chat.enableCheckpoint true"
if [[ -e ~/.toolbox/bin/claude ]]; then
  alias c="claude --mcp-config ~/.claude/mcp.json"
fi
