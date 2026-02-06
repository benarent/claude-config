# Log Analysis Scenarios

## Teleport Audit Logs

### Scenario: Security Audit

```bash
/log-analyze ~/teleport-audit.json --mode security-audit
```

**What to look for:**
- Failed login attempts (`user.login` with `success: false`)
- Privilege escalation (`user.role.created`, `user.role.updated`)
- Unusual access patterns (off-hours activity)
- Session hijacking indicators (session reuse from different IPs)

**Sample analysis prompt:**
```
Analyze for security issues:
1. Failed authentication attempts - group by user, IP, time
2. Privilege changes - who modified roles, when
3. Suspicious session patterns - unusual duration, commands
4. Access anomalies - geographic, temporal
```

**Expected findings:**
```json
{
  "security_events": [
    {
      "type": "brute_force_attempt",
      "user": "admin",
      "source_ip": "203.0.113.50",
      "attempts": 15,
      "time_window": "5 minutes",
      "lines": [1234, 1240, 1245]
    }
  ],
  "recommendations": [
    {
      "priority": "critical",
      "action": "Block IP 203.0.113.50",
      "reason": "15 failed login attempts in 5 minutes"
    }
  ]
}
```

### Scenario: Session Timeline

```bash
/log-analyze ~/teleport-audit.json --mode timeline
```

**Focus areas:**
- Session start/end pairs
- Commands executed within sessions
- File transfers (scp events)
- Database queries (db.session events)

---

## journalctl / systemd Logs

### Scenario: Service Crash Investigation

```bash
# Fetch logs from remote server
/log-analyze --remote root@prod-01 --cmd "journalctl -u myservice --since '6 hours ago'" --mode error-triage
```

**What to look for:**
- Service restart patterns (Started/Stopped cycles)
- OOM kills
- Segfaults
- Dependency failures

**Sample output:**
```json
{
  "crash_events": [
    {
      "timestamp": "2024-01-15T14:32:00Z",
      "type": "oom_kill",
      "process": "myservice",
      "memory_limit": "512MB",
      "line": 4523
    }
  ],
  "patterns": [
    {
      "description": "Service restarts every ~2 hours",
      "occurrences": 3,
      "correlation": "Memory leak suspected"
    }
  ]
}
```

### Scenario: Boot Analysis

```bash
/log-analyze --remote ubuntu@server --cmd "journalctl -b" --mode timeline
```

---

## ESP32 Serial Logs

### Scenario: WiFi Connection Issues

```bash
/log-analyze ~/esp32-serial.log --mode error-triage
```

**Common patterns:**
- WiFi disconnects (`E (xxx) wifi:`)
- Memory allocation failures
- Watchdog timeouts
- Stack overflow

**ESP32-specific analysis:**
```json
{
  "hardware_events": [
    {
      "type": "wifi_disconnect",
      "count": 12,
      "pattern": "Every ~30 minutes",
      "error_code": "WIFI_REASON_BEACON_TIMEOUT"
    },
    {
      "type": "memory_warning",
      "heap_free": "15KB",
      "threshold": "10KB",
      "line": 8934
    }
  ],
  "recommendations": [
    {
      "priority": "high",
      "title": "WiFi stability",
      "description": "Beacon timeout suggests weak signal or router issues"
    }
  ]
}
```

### Scenario: Crash Dump Analysis

```bash
/log-analyze ~/esp32-crash.log --mode error-triage
```

**Look for:**
- Backtrace addresses
- Exception causes
- Register dumps
- Core panic reasons

---

## nginx Logs

### Scenario: 5xx Error Spike

```bash
/log-analyze --remote ubuntu@web01 --cmd "cat /var/log/nginx/error.log" --mode error-triage
```

**Analysis focus:**
- Upstream connection failures
- Timeout patterns
- Client abort rates
- Buffer overflow warnings

### Scenario: Traffic Anomalies

```bash
/log-analyze ~/nginx-access.log --mode pattern-detect
```

**Look for:**
- Request rate spikes
- Unusual user agents
- Path scanning patterns
- Geographic anomalies

---

## syslog

### Scenario: Auth Failures

```bash
/log-analyze /var/log/auth.log --mode security-audit
```

**Focus:**
- SSH brute force attempts
- sudo abuse
- PAM failures
- Account lockouts

---

## Remote Log Fetch Examples

### Single Service Logs
```bash
/log-analyze --remote root@prod-db --cmd "journalctl -u postgresql --since '1 hour ago'" --mode error-triage
```

### Multiple Services
```bash
/log-analyze --remote admin@gateway --cmd "journalctl -u nginx -u teleport --since '30 min ago'" --mode timeline
```

### Kernel Logs
```bash
/log-analyze --remote root@server --cmd "dmesg -T" --mode error-triage
```

### Filtered by Priority
```bash
/log-analyze --remote root@server --cmd "journalctl -p err --since yesterday" --mode error-triage
```

### Container Logs
```bash
/log-analyze --remote deploy@k8s-node --cmd "kubectl logs -n prod deployment/api --since=1h" --mode error-triage
```

---

## Output Examples

### Markdown Summary

```markdown
## Log Analysis: teleport-audit.json

**Lines:** 45,234 | **Format:** Teleport JSON | **Mode:** security-audit
**Time Range:** 2024-01-15 00:00 - 23:59 UTC

### Severity
| Level | Count |
|-------|-------|
| Error | 23 |
| Warning | 156 |
| Info | 45,055 |

### Key Findings

1. **[CRITICAL] Brute Force Detected**
   - IP: 203.0.113.50
   - 47 failed logins for user 'admin'
   - Time: 14:30-14:35 UTC
   - Recommendation: Block IP immediately

2. **[HIGH] Privilege Escalation**
   - User 'bob' granted admin role
   - By: user 'alice'
   - Time: 16:45 UTC
   - Verify this was authorized

3. **[MEDIUM] Unusual Session Duration**
   - Session ID: sess-abc123
   - Duration: 8.5 hours (avg: 45 min)
   - Review session commands
```

### JSON Output

```json
{
  "metadata": {
    "file_path": "teleport-audit.json",
    "total_lines": 45234,
    "analysis_mode": "security-audit",
    "log_format": "teleport-json",
    "time_range": {
      "start": "2024-01-15T00:00:00Z",
      "end": "2024-01-15T23:59:59Z"
    }
  },
  "summary": {
    "severity_counts": {
      "error": 23,
      "warning": 156,
      "info": 45055
    },
    "top_event_types": [
      {"type": "session.data", "count": 38000},
      {"type": "session.start", "count": 3500},
      {"type": "session.end", "count": 3450},
      {"type": "user.login", "count": 284}
    ]
  },
  "events": [...],
  "patterns": [...],
  "recommendations": [...]
}
```
