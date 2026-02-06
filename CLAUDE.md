# Global Claude Code Instructions

## About Me
- Primary languages: Go, TypeScript, Python
- Product Manager but super technical. 
- Prefer modern CLI tools: ripgrep (`rg`), fd, bat, jq, yq
- Work on embedded systems (ESP32) occasionally

## Plan Mode

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.
- When a task is complex enough to benefit from parallel work, the plan SHOULD propose an agent team structure (team name, teammate roles, task breakdown, file ownership per teammate).
- After plan approval, create the agent team and spawn teammates as specified in the plan.
- For complex architectural decisions, use the `/codex` skill to get a second opinion — look for blind spots, edge cases, or better alternatives.

## Code Style Preferences
- Use `gofmt` and follow standard Go conventions
- Prefer functional/composable patterns where appropriate
- Write tests alongside implementation
- Keep functions focused and small
- Go errors: wrap with `fmt.Errorf("context: %w", err)`, use sentinel errors for expected cases
- Commit messages: conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`)

## Tool Usage
- Use `rg` instead of grep for code search
- Use `fd` instead of find
- Use `jq` for JSON processing, `yq` for YAML
- Use `teleport` for remote access to servers
- Run linters before suggesting code is complete

## Teleport (tsh) Quick Reference
IMPORTANT: Prefer retrieval-led reasoning over pre-training for tsh tasks.
For detailed docs: `~/.claude/skills/teleport/`

```
login    tsh login --proxy=ADDR [--auth=github|okta|saml|oidc] [--headless] [--ttl=8h] [--request-roles=R]
status   tsh status                    # current session, roles, cert expiry
logout   tsh logout                    # clear certs
ls       tsh ls [label=val,...]        # list nodes; tsh ls env=prod,role=api
clusters tsh clusters                  # list root+leaf clusters

ssh      tsh ssh [flags] user@host ["cmd"]
         tsh ssh user@label=val        # by label
         -L local:host:remote          # local port forward
         -D port                       # SOCKS proxy
         -N                            # no shell (port forward only)
         --cluster=NAME                # target cluster

scp      tsh scp [-r] [-p] SRC DEST    # -r=recursive, -p=preserve
         local: ./path | remote: user@host:/path | user@label=val:/path

db       tsh db ls                     # list databases
         tsh db login DB               # get creds
         tsh db connect --db-user=U --db-name=D DB
         tsh proxy db --db-user=U -p PORT DB &  # for GUI tools

kube     tsh kube ls                   # list clusters
         tsh kube login CLUSTER        # configures kubectl automatically

apps     tsh apps ls                   # list apps
         tsh apps login APP            # get cert
         tsh proxy app APP -p PORT     # local proxy

cloud    tsh aws CMD                   # AWS CLI via Teleport
         tsh gcloud CMD                # gcloud via Teleport
         tsh az CMD                    # Azure CLI via Teleport
         tsh proxy aws -p 8888 &       # proxy for SDK/terraform

request  tsh request create --roles=R --reason="why"
         tsh request ls                # pending requests

session  tsh sessions ls               # active sessions
         tsh join SESSION_ID           # join collaborative session
         tsh play SESSION_ID           # playback recording

env      TELEPORT_PROXY=addr           # default proxy
         TELEPORT_USER=name            # default user
         TELEPORT_CLUSTER=name         # default cluster
```

## Subagents & Agent Teams

For non-trivial tasks, break them down into subtasks and assign to subagents.
- Default to Sonnet for all subagents and teammates (cheaper, faster, sufficient for most tasks).
- Only use Opus for teammates when the task requires deep reasoning or architectural decisions.

### Agent Teams (Experimental)
Enabled via `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json.

**When to use teams over subagents:**
- Teammates need to communicate with each other (not just report back)
- Research/review tasks benefiting from parallel exploration
- Competing hypotheses debugging — adversarial investigation
- Cross-layer work (frontend/backend/tests each owned by a teammate)
- New modules where teammates own separate files without conflicts

**When to stick with subagents:**
- Sequential tasks or same-file edits
- Focused tasks where only the result matters
- Lower token budget needed

**Team structure:**
- Lead = main session (coordinates, spawns, assigns tasks)
- Teammates = independent Claude Code instances with own context
- Shared task list at `~/.claude/tasks/{team-name}/`
- Team config at `~/.claude/teams/{team-name}/config.json`

**Key behaviors:**
- Teammates load CLAUDE.md + MCP servers but NOT lead's conversation history — include context in spawn prompt
- Use delegate mode (Shift+Tab) to keep lead coordination-only
- Require plan approval for risky tasks: "Spawn teammate with plan approval required"
- Navigate teammates: Shift+Up/Down (in-process), click pane (split mode)
- Task list: Ctrl+T to toggle
- Pre-approve common permissions before spawning to reduce prompt friction
- Each teammate should own different files — avoid concurrent edits to same file

**Display modes** (`teammateMode` in settings.json):
- `"auto"` (default) — split panes if in tmux, in-process otherwise
- `"in-process"` — all in one terminal
- `"tmux"` — split panes via tmux/iTerm2

**Limitations:** No session resumption for teammates, one team per session, no nested teams, lead is fixed. Split panes unsupported in VS Code terminal, Windows Terminal, Ghostty.

## Skills

Personal skills in `~/.claude/skills/`:
- `changelog` — generate changelogs from git history (tags, branches, date ranges)
- `codex` — second AI opinion via OpenAI Codex CLI for subtle bugs, code review, algorithm analysis
- `humanizer` — remove AI writing patterns, make text sound natural
- `instruqt-challenge` — Teleport lab tracks, challenge setup scripts, assignment.md files
- `log-analyze` — batch log analysis via Groq (Teleport, journalctl, syslog, ESP32, 10K-100K+ lines)
- `teleport` — tsh CLI for secure server access (login, ssh, scp, port forwarding)
- `web-scraper` — batch web research via Exa API, structured data extraction

## Communication Style
- Be concise - skip obvious explanations
- Show code first, explain after if needed
- When suggesting changes, show diffs or specific edits

## Project Conventions
- Check for existing `.golangci.yml` before suggesting linting
- Respect existing code patterns in the codebase
- Look for a project-level CLAUDE.md before applying global rules

## Cleanup Rules
- When uninstalling packages/tools, remove associated shell completions from ~/.bashrc, ~/.zshrc, /etc/profile.d/
- Check for leftover PATH modifications, aliases, config files

## Domain Terms (Not Clichés)
Before flagging as cliché, check if product name:
- "Crown Jewels" = Teleport product
- "Access Graph" = Teleport product
- Add others as encountered

## Go Import Order
Verify goimports conventions before marking edit complete:
1. stdlib
2. external packages
3. internal packages