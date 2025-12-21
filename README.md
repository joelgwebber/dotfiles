# Initialization
```sh
source ~/.s3kr1tz.sh
source ~/dotfiles/shared.sh
```

# `.s3kr1tz.sh`
```sh
export OPENROUTER_API_KEY="..."
export TAVILY_API_KEY="..."
export ANTHROPIC_API_KEY="..."
export GEMINI_API_KEY="..."
export CONTEXT7_API_KEY="..."
export OPENAI_API_KEY="..."
export BRAVE_API_KEY="..."
```

# Symlinks
```sh
ln -s ./claude/settings.json ~/.claude/settings.json
ln -s ./kitty/ ~/.config/kitty
ln -s ./nvim/ ~/.config/nvim
ln -s ./serena/ ~/.serena
```

# MCP Servers
```sh
claude mcp add --scope user serena -- uvx --from git+https://github.com/oraios/serena serena start-mcp-server --context ide-assistant
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```

# Claude Plugins
```
/plugin marketplace add steveyegge/beads
/plugin install beads
```

