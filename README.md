# claude-config

Personal Claude Code configuration, skills, and settings.

## What's synced

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions |
| `settings.json` | Model, hooks, plugins, statusline |
| `statusline-command.sh` | Robbyrussell-style status bar |
| `skills/` | Custom skills (codex, humanizer, teleport, etc.) |

## What's NOT synced

- `settings.local.json` — machine-specific permissions (gitignored)
- `history.jsonl`, `session-env/`, `debug/` — ephemeral session data
- `plugins/` — managed by Claude Code plugin system

## Setup on a new machine

```bash
git clone https://github.com/benarent/claude-config.git
cd claude-config
./sync.sh pull
```

## Workflow

```bash
# After editing config locally
./sync.sh push
git add -A && git commit -m "update config"
git push

# On another machine
git pull
./sync.sh pull
```
