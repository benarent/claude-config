---
name: instruqt-challenge
description: This skill should be used when working with Instruqt tracks, creating or modifying challenges, updating setup scripts, or editing assignment.md files. Use for Teleport lab development, track validation, and challenge configuration.
---

# Instruqt Challenge Development

Create and modify Instruqt track challenges for Teleport labs.

## Track Structure

```
track-name/
├── track.yml              # Track metadata, tabs, environment config
├── TRACK-NOTES.md         # Developer notes (not shown to participants)
├── assets/                # Images, diagrams for assignments
│   └── *.png
├── 01-challenge-slug/
│   ├── assignment.md      # Challenge content (frontmatter + markdown)
│   ├── setup-<host>       # Setup scripts per host (bash, runs before challenge)
│   ├── check-<host>       # Check scripts (validates completion)
│   └── solve-<host>       # Solve scripts (auto-solve for testing)
├── 02-challenge-slug/
│   └── ...
```

## Challenge Files

### assignment.md Structure

```markdown
---
slug: challenge-slug
id: <instruqt-generated>
type: challenge
title: Challenge Title
teaser: Short description for challenge card
notes:
- type: text
  contents: |-
    ## Pre-challenge Info
    Shown before challenge starts
tabs:
- id: <instruqt-generated>
  title: Tab Name
  type: terminal|website|code
  hostname: <host>         # for terminal
  url: https://...         # for website
difficulty: basic|intermediate|advanced
timelimit: 600             # seconds
---

Content shown during challenge...
```

### Setup Scripts

- Filename: `setup-<hostname>` (e.g., `setup-teleportvm`, `setup-prod-host`)
- Must start with `#!/bin/bash -l` (login shell for env vars)
- Run before participant sees the challenge
- Access env vars: `${_SANDBOX_ID}`, `${PARTICIPANT_ID}`

### Check Scripts

- Filename: `check-<hostname>`
- Exit 0 = pass, non-zero = fail
- Print error message before failing

## Common Patterns

### Teleport Role Creation (setup-teleportvm)

```bash
#!/bin/bash -l
tctl create -f << 'EOF'
kind: role
version: v7
metadata:
  name: role-name
spec:
  allow:
    logins: ['ubuntu']
    node_labels:
      env: prod
EOF
```

### Database Setup (setup-prod-host)

```bash
#!/bin/bash -l
# PostgreSQL user for Teleport Database Access Controls
sudo -u postgres psql -c "CREATE USER \"teleport-admin\" WITH CREATEROLE;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE dbname TO \"teleport-admin\";"
```

### Teleport Config with Database Admin User

```yaml
db_service:
  enabled: "yes"
  databases:
  - name: prod-postgres
    protocol: postgres
    uri: localhost:5432
    admin_user:
      name: teleport-admin
    static_labels:
      env: prod
```

### Assignment Markdown Patterns

```markdown
Section Title
=========

Explanation text...

## Subsection

**Bold label:**
\```bash
command here
\```

\```sql
SELECT * FROM table;
\```

> [!NOTE]
> Callout text for important info

[button label="Open Link"](https://...)
```

## Workflow

### Creating a New Challenge

1. Create directory: `<NN>-<slug>/`
2. Create `assignment.md` with frontmatter
3. Create setup scripts for each host that needs configuration
4. Create check script to validate completion
5. Run `instruqt track validate`

### Modifying Existing Challenge

1. Read existing files to understand current state
2. Modify setup scripts to add new functionality
3. Update assignment.md with new instructions
4. Run `instruqt track validate`
5. Run `instruqt track push` to deploy

### Testing

```bash
instruqt track validate    # Validate track structure
instruqt track push        # Push to Instruqt
instruqt track test        # Run automated tests
```

## Environment Variables

Available in setup/check scripts:
- `${_SANDBOX_ID}` - Unique sandbox identifier
- `${PARTICIPANT_ID}` - Instruqt participant ID
- `${INSTRUQT_*}` - Various Instruqt-provided vars

## Hosts

Common hosts in Teleport tracks:
- `teleportvm` - Main Teleport cluster (auth + proxy)
- `prod-host` / `production-host` - Production server with Teleport agent
- `workstation` - User workstation for tsh commands
