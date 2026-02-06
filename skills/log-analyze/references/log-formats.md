# Log Format Detection

## Format Signatures

### Teleport JSON Events

**Signature:**
```
Lines start with {"ei": or contain "event":"
```

**Detection:**
```bash
head -100 "$FILE" | grep -c '{"ei":' > 0
# or
head -100 "$FILE" | grep -c '"event":"' > 0
```

**Sample:**
```json
{"ei":0,"event":"session.start","uid":"abc123","time":"2024-01-15T10:00:00Z","user":"alice","sid":"sess-001"}
{"ei":1,"event":"session.data","uid":"abc124","time":"2024-01-15T10:00:01Z","data":"Y2QgL3Zhci9sb2c="}
{"ei":2,"event":"session.end","uid":"abc125","time":"2024-01-15T10:05:00Z","sid":"sess-001"}
```

**Key Fields:**
- `event` - Event type (session.start, session.end, user.login, etc.)
- `time` - ISO timestamp
- `user` - Username
- `sid` - Session ID
- `ei` - Event index

**Session Boundaries:**
- Start: `"event":"session.start"`
- End: `"event":"session.end"`

---

### journalctl

**Signature:**
```
^[A-Z][a-z]{2} [ 0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}
```

**Detection:**
```bash
head -100 "$FILE" | grep -cE '^[A-Z][a-z]{2} [ 0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' > 0
```

**Sample:**
```
Jan 15 10:00:00 server01 teleport[1234]: Starting Teleport v14.0.0
Jan 15 10:00:01 server01 teleport[1234]: Auth server listening on 0.0.0.0:3025
Jan 15 10:00:05 server01 sshd[5678]: Accepted publickey for root from 192.168.1.100
```

**Key Fields:**
- Timestamp: Month Day HH:MM:SS
- Hostname
- Service name + PID
- Message

---

### Syslog (RFC 3164/5424)

**Signature:**
```
^<[0-9]+> or traditional syslog timestamp
```

**Detection:**
```bash
head -100 "$FILE" | grep -cE '^<[0-9]+>' > 0
```

**Sample (RFC 5424):**
```
<34>1 2024-01-15T10:00:00.000Z server01 myapp 1234 ID47 - Connection established
<165>1 2024-01-15T10:00:05.000Z server01 myapp 1234 ID48 [exampleSDID@32473 iut="3"] Error occurred
```

**Sample (RFC 3164):**
```
<34>Jan 15 10:00:00 server01 myapp[1234]: Connection established
```

**Priority Decoding:**
- Priority = Facility * 8 + Severity
- Facility: 0-23 (kern, user, mail, daemon, auth, syslog, lpr, news, uucp, cron, local0-7)
- Severity: 0-7 (emerg, alert, crit, err, warning, notice, info, debug)

---

### ESP32 / Arduino Serial

**Signature:**
```
Contains [ESP32], or lines match ^[EWIDV] \([0-9]+\)
```

**Detection:**
```bash
head -100 "$FILE" | grep -cE '^\[ESP32\]|^[EWIDV] \([0-9]+\)' > 0
```

**Sample:**
```
I (234) cpu_start: Starting scheduler on PRO CPU.
I (237) wifi: wifi driver task: 3ffc0f1c, prio:23, stack:3584
E (5432) wifi: esp_wifi_connect: station is not initialized
W (5433) wifi: Retrying connection...
I (10234) main: Sensor reading: 23.5C
D (10235) main: Raw ADC value: 2048
```

**Log Levels:**
- `E` - Error
- `W` - Warning
- `I` - Info
- `D` - Debug
- `V` - Verbose

**Format:** `LEVEL (timestamp_ms) tag: message`

---

### nginx Error Log

**Signature:**
```
Contains [error] or [warn] with nginx patterns
```

**Detection:**
```bash
head -100 "$FILE" | grep -cE '\[(error|warn|notice|info)\].*client:' > 0
```

**Sample:**
```
2024/01/15 10:00:00 [error] 1234#5678: *9 connect() failed (111: Connection refused) while connecting to upstream, client: 192.168.1.100, server: example.com, request: "GET /api/health HTTP/1.1", upstream: "http://127.0.0.1:8080/api/health"
2024/01/15 10:00:05 [warn] 1234#5678: *10 an upstream response is buffered to a temporary file
```

**Key Fields:**
- Timestamp: YYYY/MM/DD HH:MM:SS
- Level: [error], [warn], [notice], [info]
- PID#TID
- Connection number (*)
- Client IP
- Request details

---

### nginx Access Log (Combined Format)

**Signature:**
```
IP - - [timestamp] "METHOD /path HTTP/x.x" status size
```

**Detection:**
```bash
head -100 "$FILE" | grep -cE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ - .* \[.*\] "' > 0
```

**Sample:**
```
192.168.1.100 - - [15/Jan/2024:10:00:00 +0000] "GET /api/users HTTP/1.1" 200 1234 "https://example.com" "Mozilla/5.0..."
```

---

### Generic / Unknown

**Fallback when no specific format detected.**

**Heuristics:**
- Look for timestamp patterns: ISO 8601, Unix timestamps, common date formats
- Look for severity keywords: ERROR, WARN, INFO, DEBUG, FATAL
- Look for structured patterns: key=value, JSON fragments

**Detection Strategy:**
```bash
# Try to find any timestamp
if head -100 "$FILE" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{10}'; then
  echo "Has timestamps"
fi

# Try to find severity levels
if head -100 "$FILE" | grep -qiE 'error|warn|info|debug|fatal'; then
  echo "Has severity levels"
fi
```

---

## Format Detection Script

```bash
detect_format() {
  local FILE="$1"
  local SAMPLE=$(head -100 "$FILE")

  # Teleport JSON
  if echo "$SAMPLE" | grep -q '{"ei":'; then
    echo "teleport-json"
    return
  fi

  # journalctl
  if echo "$SAMPLE" | grep -qE '^[A-Z][a-z]{2} [ 0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'; then
    echo "journalctl"
    return
  fi

  # Syslog
  if echo "$SAMPLE" | grep -qE '^<[0-9]+>'; then
    echo "syslog"
    return
  fi

  # ESP32
  if echo "$SAMPLE" | grep -qE '^\[ESP32\]|^[EWIDV] \([0-9]+\)'; then
    echo "esp32"
    return
  fi

  # nginx error
  if echo "$SAMPLE" | grep -qE '\[(error|warn)\].*client:'; then
    echo "nginx-error"
    return
  fi

  # nginx access
  if echo "$SAMPLE" | grep -qE '^[0-9.]+.*\[.*\] "(GET|POST|PUT|DELETE)'; then
    echo "nginx-access"
    return
  fi

  echo "generic"
}
```

## Session-Aware Chunking

For formats with session boundaries (Teleport, SSH), avoid splitting mid-session:

```bash
# Find session start line numbers
grep -n '"event":"session.start"' "$FILE" | cut -d: -f1 > session_starts.txt

# Chunk at session boundaries
chunk_at_sessions() {
  local LINES_PER_CHUNK=$1
  local current_chunk=1
  local lines_in_chunk=0

  while read -r line_num; do
    if [ $lines_in_chunk -ge $LINES_PER_CHUNK ]; then
      # Start new chunk at this session boundary
      current_chunk=$((current_chunk + 1))
      lines_in_chunk=0
    fi
    lines_in_chunk=$((lines_in_chunk + 1))
  done < session_starts.txt
}
```
