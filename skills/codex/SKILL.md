---
name: codex
description: "Use OpenAI Codex CLI for complex debugging, code analysis, and getting a second AI perspective on technical problems. Invoke Codex when stuck on subtle bugs, analyzing algorithms against specs, needing detailed code review, or wanting a second opinion from a different AI model."
---

# Using Codex from Claude Code

Codex is OpenAI's AI-powered CLI coding agent. Use it to get a second perspective on complex debugging, code analysis, and technical questions.

## MCP Integration (Preferred)

Claude Code has native MCP tools for Codex—use these instead of shelling out to CLI.

### `mcp__codex__codex` - Start Session

```json
{
  "prompt": "Review this function for race conditions",
  "cwd": "/path/to/project",
  "sandbox": "read-only",
  "approval-policy": "untrusted",
  "model": "gpt-5.2-codex"
}
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `prompt` | ✅ | Initial prompt to start the conversation |
| `cwd` | | Working directory (defaults to server cwd) |
| `model` | | Model override (e.g., `gpt-5.2`, `gpt-5.2-codex`) |
| `sandbox` | | `read-only`, `workspace-write`, `danger-full-access` |
| `approval-policy` | | `untrusted`, `on-failure`, `on-request`, `never` |
| `base-instructions` | | Replace default system instructions |
| `developer-instructions` | | Inject as developer role message |
| `profile` | | Load profile from `~/.codex/config.toml` |
| `config` | | Inline config overrides (object) |

### `mcp__codex__codex-reply` - Continue Session

```json
{
  "threadId": "thread_abc123",
  "prompt": "Now show me the fix"
}
```

| Parameter | Required | Description |
|-----------|----------|-------------|
| `threadId` | ✅ | Thread ID from previous response |
| `prompt` | ✅ | Follow-up message |

### MCP Example Flow

```
1. Call mcp__codex__codex with initial prompt
2. Get response with threadId
3. Call mcp__codex__codex-reply with threadId + follow-up
4. Repeat step 3 for multi-turn conversations
```

---

## CLI Fallback (`codex exec`)

Use CLI when MCP isn't available or you need file I/O, image attachments, or structured JSON output.

**Important:** Always use `codex exec` (not bare `codex` which launches an interactive TUI that Claude Code cannot operate).

## When to Use Codex

- Debugging subtle bugs (bitstream alignment, off-by-one errors, race conditions)
- Analyzing complex algorithms against specifications
- Getting detailed code review with specific bug identification
- Understanding obscure file formats or protocols
- When multiple approaches have failed and you want a different AI's perspective

## Quick Reference

| Task | Command |
|------|---------|
| Simple query | `codex exec "your question" --full-auto` |
| Query with file output | `codex exec "your question" -o /tmp/reply.txt --full-auto` |
| Pipe input from file | `codex exec - --full-auto < /tmp/question.txt` |
| JSON output for parsing | `codex exec "your question" --json --full-auto` |
| Resume previous session | `codex exec resume --last "follow-up question"` |
| Attach image | `codex exec -i screenshot.png "analyze this error" --full-auto` |

## Command: `codex exec`

Non-interactive execution mode for scripted/CI-style runs.

### Core Flags

| Flag | Description |
|------|-------------|
| `--full-auto` | Unattended mode: `workspace-write` sandbox + approvals on failure only |
| `-o, --output-last-message PATH` | Write final message to file (also prints to stdout) |
| `--json` | Output JSON Lines stream of all events to stdout |
| `--output-schema PATH` | Request structured JSON output conforming to schema file |
| `-m, --model MODEL` | Override model (e.g., `gpt-5-codex`, `gpt-5`) |
| `-i, --image PATH` | Attach image(s) to prompt (repeatable, comma-separated) |
| `-C, --cd PATH` | Set working directory before execution |
| `-p, --profile NAME` | Load config profile from `~/.codex/config.toml` |

### Sandbox & Approval Flags

| Flag | Description |
|------|-------------|
| `-s, --sandbox MODE` | `read-only` (default), `workspace-write`, or `danger-full-access` |
| `-a, --ask-for-approval MODE` | `untrusted`, `on-failure`, `on-request`, or `never` |
| `--skip-git-repo-check` | Allow running outside a Git repository |
| `--yolo` | Bypass all approvals and sandboxing (dangerous!) |

### Input Methods

```bash
# Direct prompt argument
codex exec "explain this algorithm" --full-auto

# Pipe from stdin using -
codex exec - --full-auto < /tmp/question.txt

# Pipe directly (prompt reads from stdin)
cat /tmp/question.txt | codex exec - --full-auto
```

### Output Behavior

- Progress streams to `stderr`
- Final agent message prints to `stdout`
- Use `-o PATH` to also write final message to a file
- Use `--json` for machine-readable JSON Lines stream

## The File-Based Pattern (Recommended for Complex Problems)

For debugging complex issues, structure your question in a file:

### Step 1: Create Question File

```bash
cat > /tmp/question.txt << 'EOF'
Problem: [Clear problem statement]

Error/Symptom: [Specific error message or behavior]

Here is the full function:
```language
[paste COMPLETE code - don't truncate]
```

Key observations:
1. [What works]
2. [What fails]
3. [Conditions when it fails]

Questions:
1. [Specific question 1]
2. [Specific question 2]
EOF
```

### Step 2: Run Codex

```bash
codex exec - -o /tmp/reply.txt --full-auto < /tmp/question.txt
```

### Step 3: Read Response

```bash
cat /tmp/reply.txt
```

## Session Resume

Continue previous sessions for multi-step analysis:

```bash
# Initial analysis
codex exec "review this code for race conditions" --full-auto

# Continue with follow-up
codex exec resume --last "now fix the race conditions you found"

# Or resume specific session by ID
codex exec resume SESSION_ID "implement the suggested fix"
```

## Structured Output

For automation, request JSON conforming to a schema:

```bash
# schema.json
{
  "type": "object",
  "properties": {
    "bugs_found": { "type": "array", "items": { "type": "string" } },
    "severity": { "type": "string", "enum": ["low", "medium", "high", "critical"] }
  },
  "required": ["bugs_found", "severity"]
}

# Run with schema
codex exec "analyze for bugs" --output-schema ./schema.json -o result.json --full-auto
```

## Image Analysis

Attach screenshots or diagrams:

```bash
codex exec -i error_screenshot.png "what's causing this error?" --full-auto
codex exec -i diagram.png,spec.png "does implementation match spec?" --full-auto
```

## Authentication

For Claude Code (non-interactive), use macOS Keychain for secure key storage:

```bash
# One-time setup: store key in Keychain
security add-generic-password -a "$USER" -s "openai-api-key" -w "sk-..."

# In ~/.zshrc
export OPENAI_API_KEY=$(security find-generic-password -a "$USER" -s "openai-api-key" -w 2>/dev/null)
```

Alternative methods:
```bash
# Option 1: Inline env var
CODEX_API_KEY=sk-... codex exec "task" --full-auto

# Option 2: Pipe to login (persists credentials)
echo "$OPENAI_API_KEY" | codex login --with-api-key

# Option 3: Check login status
codex login status
```

**Note:** Browser-based `codex login` (without flags) requires interactive terminal — don't use from Claude Code.

## Example: Debug Session

```bash
# 1. Create detailed question
cat > /tmp/question.txt << 'EOF'
Problem: Progressive JPEG decoder fails at block 1477 with "Invalid Huffman code"

Here is the AC refinement function:
```c
void decode_ac_refinement(bitstream *bs, int16_t *block, int start, int end) {
    // [full 50-line function here]
}
```

The JPEG spec (ITU-T.81 Section F.2.4.3) defines AC refinement as:
1. Read EOB run if applicable
2. Process coefficients from start to end
3. Handle ZRL specially

Observed behavior:
- Works for first 1476 blocks
- Fails on block 1477, coefficient position 12
- Same image decodes fine in libjpeg

Questions:
1. Is EOB run counting correct per spec?
2. Is the ZRL (zero run length) handling correct?
3. Are we properly distinguishing new vs refinement bits?
EOF

# 2. Get analysis
codex exec - -o /tmp/analysis.txt --full-auto < /tmp/question.txt

# 3. Review
cat /tmp/analysis.txt

# 4. Follow up if needed
codex exec resume --last "show me the corrected decode_ac_refinement function"
```

## Best Practices

1. **Provide complete code**: Don't truncate. Codex needs full context.

2. **Be specific**: "Why does Huffman decoding fail at block 1477 in AC refinement?" beats "Why does this fail?"

3. **Include specs**: Reference relevant standards (JPEG ITU-T.81, PNG RFC 2083, etc.).

4. **Verify suggestions**: Codex is helpful but not infallible—always verify against authoritative sources.

5. **Iterate with resume**: Use `codex exec resume --last` for multi-turn debugging sessions.

## Common Issues

| Problem | Solution |
|---------|----------|
| "stdin is not a terminal" | You used `codex` instead of `codex exec` |
| No output file created | Ensure `-o` path is writable |
| Timeout/blocking | Use `--full-auto` to skip approval prompts |
| "Not in a git repository" | Use `--skip-git-repo-check` or initialize git |
| Need write permissions | Use `--sandbox workspace-write` or `danger-full-access` |
| Authentication error | Set `CODEX_API_KEY` env var or pipe key to `codex login --with-api-key` |

## Model Selection

```bash
# Use specific model
codex exec -m gpt-5-codex "analyze this" --full-auto
codex exec -m gpt-5 "analyze this" --full-auto

# Use local model via Ollama
codex exec --oss "analyze this" --full-auto
```

## Related Commands

| Command | Purpose | Use from Claude Code? |
|---------|---------|----------------------|
| `codex exec` | Non-interactive scripted execution | ✅ Yes - primary command |
| `codex exec resume` | Continue non-interactive session | ✅ Yes |
| `codex login` | Authenticate | ✅ Yes (with `--with-api-key`) |
| `codex` | Interactive TUI session | ❌ No - requires terminal interaction |
| `codex resume` | Continue interactive session | ❌ No - requires terminal interaction |

## MCP vs CLI: When to Use Which

| Use Case | Recommended |
|----------|-------------|
| Simple query, no file I/O | **MCP** - cleaner, no shell overhead |
| Multi-turn conversation | **MCP** - threadId handles context |
| Need to attach images | CLI (`-i` flag) |
| Need structured JSON output | CLI (`--output-schema`) |
| Write response to file | CLI (`-o` flag) |
| Complex prompt from file | CLI (stdin redirection) |
| MCP unavailable | CLI fallback |
