# Claude Code config

## Launch modes

- `claude`: acceptEdits; sandboxed Bash runs without prompts except `ask.txt` rules (reads anywhere except `~/.ssh`, `~/.aws`, `~/.gnupg`; writes only in cwd + allowed roots). MCP tools other than context7 and web fetches still prompt. Because of the read block, git over SSH and AWS CLI auth don't work from Claude's Bash.
- `claude --settings ~/.claude/profiles/strict.json`: same, plus no reads outside cwd (shell and file tools).

Shell alias and launch guard (add to `~/.zshrc`):

```sh
alias claude-strict='claude --settings ~/.claude/profiles/strict.json'

# While any sandboxed Bash command runs, the sandbox leaves an empty
# ~/.claude/.config.json mount point. Claude Code reads that path as its legacy
# global config instead of ~/.claude.json: it either refuses to start ("JSON
# Parse error: Unexpected EOF") or saves a fresh config there, which then
# shadows ~/.claude.json. Remove it (or move it aside if non-empty) at launch.
claude() {
    local legacy="$HOME/.claude/.config.json"
    if [[ -f $legacy && ! -L $legacy && -f $HOME/.claude.json ]]; then
        if [[ -s $legacy ]]; then
            mv -- "$legacy" "$legacy.stray.$(date +%s)"
        else
            rm -f -- "$legacy"
        fi
    fi
    command claude "$@"
}
```

## Bash deny/ask rules

Edit `permissions/deny.txt` or `permissions/ask.txt`, then run `bash ~/.claude/permissions/generate.sh` to write them into `settings.json` (adds `rtk <cmd>` / `rtk * <cmd>` variants). Non-Bash deny rules such as `Read(~/.ssh/**)` live directly in `settings.json` and survive regeneration; a `Read` deny also blocks sandboxed Bash from reading the path.

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
