# Claude Code config

## Launch modes

- `claude`: bypassPermissions; Bash sandboxed (reads anywhere, writes only in cwd + allowed roots).
- `claude --settings ~/.claude/profiles/strict.json`: same, plus no reads outside cwd (shell and file tools).

Shell alias (add to `~/.zshrc`):

```sh
alias claude-strict='claude --settings ~/.claude/profiles/strict.json'
```

## Bash deny/ask rules

Edit `permissions/deny.txt` or `permissions/ask.txt`, then run `bash ~/.claude/permissions/generate.sh` to write them into `settings.json` (adds `rtk <cmd>` / `rtk * <cmd>` variants).

## One-time setup (run in a normal terminal; ~/.claude.json and plugins/ are outside the sandbox)

```sh
# skills shared with other agents
mv ~/.claude/skills ~/.claude/skills.bak && ln -s ~/.agents/skills ~/.claude/skills

# MCP servers (user scope, stored in ~/.claude.json)
claude mcp add -s user --transport http context7 https://mcp.context7.com/mcp
claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@1.10.1 --autoConnect

# LSP plugins (binaries must be on PATH)
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin install gopls-lsp@claude-plugins-official
claude plugin install rust-analyzer-lsp@claude-plugins-official
claude plugin install lua-lsp@claude-plugins-official
claude plugin marketplace add ~/.claude/local-plugins
claude plugin install terraform-lsp@personal
```

MCP servers run outside the Bash sandbox and the Edit/Write hook (e.g. chrome-devtools can save screenshots anywhere).

chrome-devtools `--autoConnect` attaches to your running Chrome: enable it once at `chrome://inspect/#remote-debugging`.
