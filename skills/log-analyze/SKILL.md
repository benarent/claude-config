---
name: log-analyze
description: Batch log analysis using Groq's fast inference. Handles 10K-100K+ line files from Teleport, journalctl, syslog, ESP32.
triggers:
  - "analyze logs"
  - "log analysis"
  - "parse logs"
  - "debug logs"
  - "triage errors"
args:
  - name: file
    description: Path to log file (local or temp from remote fetch)
    required: false
  - name: mode
    description: "Analysis mode: error-triage, pattern-detect, timeline, security-audit"
    default: error-triage
  - name: remote
    description: "Remote host (user@host) to fetch logs via tsh ssh"
    required: false
  - name: cmd
    description: "Command to run on remote host (e.g., journalctl -u teleport)"
    required: false
---

# Log Analyzer Skill

Fast log analysis using Groq inference. Deduplicate before sending to LLM.

## Prerequisites

`GROQ_API_KEY` must be set. Get key at https://console.groq.com/keys

---

## Orchestration: Silent Until Analysis

**Goal:** Zero log content in conversation. Only show final Groq analysis.

### Call 1: Fetch via SCP (silent, with timeout + fallback)

Save logs on remote, then SCP locally. Falls back to capped pipe if SCP fails.

```bash
REMOTE="user@host"
CMD="journalctl -u teleport --since '24 hours ago'"
REMOTE_TMP="/tmp/claude-logs-$$.txt"
LOCAL_FILE="$SCRATCHPAD/logs.txt"
MAX_LINES=50000  # fallback cap

# Try SCP method first (60s timeout per operation)
if timeout 60 tsh ssh "$REMOTE" "$CMD > $REMOTE_TMP 2>&1" && \
   timeout 120 tsh scp "$REMOTE:$REMOTE_TMP" "$LOCAL_FILE" && \
   tsh ssh "$REMOTE" "rm -f $REMOTE_TMP"; then
  echo "fetched"
else
  # Fallback: capped pipe (still uses tokens, but bounded)
  echo "scp failed, fallback to capped fetch"
  timeout 60 tsh ssh "$REMOTE" "$CMD" 2>&1 | head -n $MAX_LINES > "$LOCAL_FILE"
fi
```

For local files, skip to Call 2 with `LOCAL_FILE="/path/to/logs.txt"`.

### Call 2: Dedupe + Groq (single Bash, silent processing)

Extract, dedupe, send to Groq—all without echoing log content:

```bash
LOCAL_FILE="$SCRATCHPAD/logs.txt"

# Build payload silently (no echo)
STATS=$(cat <<EOF
Lines: $(wc -l < "$LOCAL_FILE")
Errors: $(rg -c 'ERROR|Error' "$LOCAL_FILE" 2>/dev/null || echo 0)
Warns: $(rg -c 'WARN' "$LOCAL_FILE" 2>/dev/null || echo 0)
EOF
)

UNIQUE_ERRORS=$(rg "Original Error:" "$LOCAL_FILE" 2>/dev/null | cut -d: -f4- | sort | uniq -c | sort -rn | head -20)
UNIQUE_WARNS=$(rg -o 'WARN \[[A-Z0-9:_-]+\]' "$LOCAL_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10)
ERROR_SAMPLES=$(rg -B1 -A2 'ERROR|Error' "$LOCAL_FILE" 2>/dev/null | head -50)

PAYLOAD="$STATS

UNIQUE ERRORS:
$UNIQUE_ERRORS

UNIQUE WARN COMPONENTS:
$UNIQUE_WARNS

ERROR CONTEXT SAMPLES:
$ERROR_SAMPLES"

# Progress indicator, then send to Groq
echo "analyzing $(wc -l < "$LOCAL_FILE" | tr -d ' ') lines..."
curl -s https://api.groq.com/openai/v1/chat/completions \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg model "llama-3.3-70b-versatile" \
    --arg system "You are a Teleport/infrastructure expert. Analyze these deduplicated error patterns. Output JSON: {health_status, root_causes[], recommendations[], severity}" \
    --arg user "$PAYLOAD" \
    '{model:$model,messages:[{role:"system",content:$system},{role:"user",content:$user}],response_format:{type:"json_object"},temperature:0.1}')" \
  | jq -r '.choices[0].message.content'
```

### Output: Markdown Report

```markdown
## Log Analysis - [hostname]

**File:** N lines
**Period:** start → end
**Format:** journalctl

### Health: [HEALTHY/DEGRADED/UNHEALTHY]

### Severity
| Level | Count | % |
|-------|-------|---|
| ERROR | N | X% |
| WARN | N | X% |
| INFO | N | X% |

### Root Causes
1. **Issue** - description (N occurrences)

### Recommendations
1. [HIGH] Action
2. [MEDIUM] Action
```

---

## Key Rules

### DO:
- Use SCP for remote logs (no content in conversation)
- Wrap fetches with `timeout 60` (prevents hangs)
- Fall back to capped pipe if SCP fails (`head -n 50000`)
- Show progress before Groq call (`analyzing N lines...`)
- Assign all extractions to variables (no echo until Groq)
- Deduplicate before Groq (saves 99% tokens)

### DON'T:
- Echo log content, stats, or samples to stdout
- Use `tsh ssh cmd > file` (pipes through conversation)
- Use Task subagents for file operations (can't access temp files)
- Send raw logs to Groq

---

## Token Savings

| Log Size | Unique Errors | Raw Tokens | After Dedup |
|----------|---------------|------------|-------------|
| 280K lines | 4 | 5M | 5K (99.9% saved) |
| 100K lines | 50 | 2M | 30K (98.5% saved) |

## Cost

With deduplication: ~$0.01-0.05 per analysis regardless of log size.
