---
name: teleport
description: Teleport CLI (tsh) for secure access to servers, Kubernetes, databases. Login, SSH, SCP operations.
triggers:
  - "tsh"
  - "teleport"
  - "ssh to"
  - "connect to server"
  - "copy files to server"
  - "scp"
args:
  - name: action
    description: "Action: login, ssh, scp, db, kube, apps, proxy, request, status, ls"
    required: false
  - name: target
    description: "Target host, cluster, or file path"
    required: false
---

# Teleport Skill

Secure infrastructure access via Teleport's `tsh` CLI.

## Quick Reference

| Action | Command |
|--------|---------|
| Login | `tsh login --proxy=proxy.example.com` |
| SSH | `tsh ssh user@node` |
| SCP upload | `tsh scp local.txt user@node:/path/` |
| SCP download | `tsh scp user@node:/path/file.txt ./` |
| List nodes | `tsh ls` |
| Status | `tsh status` |
| Database | `tsh db connect --db-user=admin mydb` |
| Kubernetes | `tsh kube login mycluster && kubectl get pods` |
| Apps | `tsh apps login myapp && tsh proxy app myapp` |
| AWS CLI | `tsh aws s3 ls` |
| Join session | `tsh join <session-id>` |
| Request access | `tsh request create --roles=admin` |

---

## Commands

### tsh login

Authenticate to a Teleport cluster.

```bash
# Basic login (opens browser for SSO)
tsh login --proxy=teleport.example.com

# Specify cluster
tsh login --proxy=teleport.example.com --auth=github

# Login to specific cluster in multi-cluster setup
tsh login --proxy=teleport.example.com leaf-cluster

# With username
tsh login --proxy=teleport.example.com --user=alice

# Check current session
tsh status
```

**Common flags:**
- `--proxy` — Teleport proxy address (required first time)
- `--user` — Username (defaults to local user)
- `--auth` — Auth connector (github, okta, saml, oidc, local)
- `--ttl` — Session TTL (e.g., `8h`, `24h`)
- `--request-roles` — Request additional roles
- `--browser=none` — Headless mode (prints URL, no browser)
- `--headless` — Headless auth for remote/CI machines
- `--out=<file>` — Save certificate to file

**Troubleshooting:**
```bash
# Expired cert
tsh login --proxy=teleport.example.com

# Wrong cluster
tsh logout && tsh login --proxy=correct-proxy.example.com

# Debug connection issues
tsh login --proxy=teleport.example.com --debug
```

### tsh ssh

Connect to a node via SSH.

```bash
# Basic connection
tsh ssh user@hostname

# With node labels
tsh ssh user@env=prod

# Run single command
tsh ssh user@hostname "uptime"

# Port forwarding
tsh ssh -L 8080:localhost:80 user@hostname

# Dynamic SOCKS proxy
tsh ssh -D 1080 user@hostname

# X11 forwarding
tsh ssh -X user@hostname

# Specific cluster
tsh ssh --cluster=prod user@hostname
```

**Node selection:**
```bash
# By hostname
tsh ssh root@web-01

# By label
tsh ssh root@env=staging
tsh ssh root@env=prod,role=api

# Interactive node picker (if multiple matches)
tsh ssh root@role=web
```

**Session options:**
- `-L local:remote` — Local port forward
- `-R remote:local` — Remote port forward
- `-D port` — SOCKS5 proxy
- `-N` — No shell (for port forwarding only)
- `-t` — Force TTY allocation
- `--cluster` — Target cluster

### tsh scp

Copy files to/from remote nodes.

```bash
# Upload file
tsh scp ./local-file.txt user@hostname:/remote/path/

# Upload directory (recursive)
tsh scp -r ./local-dir user@hostname:/remote/path/

# Download file
tsh scp user@hostname:/remote/file.txt ./local-path/

# Download directory
tsh scp -r user@hostname:/remote/dir ./local-path/

# Preserve permissions
tsh scp -p ./file.txt user@hostname:/path/

# Specific cluster
tsh scp --cluster=prod ./file.txt user@hostname:/path/
```

**Flags:**
- `-r` — Recursive (directories)
- `-p` — Preserve modification times and modes
- `--cluster` — Target cluster

**Path formats:**
```bash
# Remote paths
user@hostname:/absolute/path
user@hostname:relative/path
user@hostname:~/home-relative

# With labels
user@env=prod:/var/log/app.log
```

### tsh db

Access databases (Postgres, MySQL, MongoDB, Redis, etc.) via Teleport.

```bash
# List available databases
tsh db ls

# Login to database (get credentials)
tsh db login mypostgres

# Connect directly
tsh db connect --db-user=admin --db-name=mydb mypostgres

# Start local proxy (for GUI tools like pgAdmin, DBeaver)
tsh proxy db --db-user=admin --db-name=mydb -p 5432 mypostgres &

# Execute query across multiple databases
tsh db exec --dbs=db1,db2 "SELECT version();"

# Logout
tsh db logout mypostgres
```

**Flags:**
- `--db-user` — Database username
- `--db-name` — Specific database name
- `-p, --port` — Local proxy port
- `--tunnel` — Enable tunnel mode for proxy

### tsh kube

Access Kubernetes clusters via Teleport.

```bash
# List available clusters
tsh kube ls

# Login to cluster (configures kubectl)
tsh kube login mycluster

# Now use kubectl normally
kubectl get pods
kubectl logs deployment/myapp

# Login to specific cluster in leaf
tsh kube login --cluster=leaf-cluster myk8s

# Start local proxy with ephemeral kubeconfig
tsh proxy kube mycluster -p 8443
```

After `tsh kube login`, kubectl is automatically configured.

### tsh apps

Access web applications and TCP apps via Teleport.

```bash
# List available apps
tsh apps ls

# Login to app (obtain certificate)
tsh apps login grafana

# Start local proxy
tsh proxy app grafana -p 8080
# Access at http://localhost:8080

# Get app certificate paths (for curl, etc.)
tsh apps config --format=uri   # https://grafana.teleport.example.com
tsh apps config --format=ca    # CA cert path
tsh apps config --format=cert  # Client cert path
tsh apps config --format=key   # Client key path

# Logout
tsh apps logout grafana
```

### tsh proxy

Start local proxies for various services.

```bash
# SSH proxy (for OpenSSH integration)
tsh proxy ssh user@hostname

# Database proxy
tsh proxy db --db-user=admin -p 5432 mypostgres

# Kubernetes proxy
tsh proxy kube mycluster -p 8443

# Application proxy
tsh proxy app grafana -p 8080

# AWS API proxy
tsh proxy aws -p 8888

# GCloud proxy
tsh proxy gcloud

# Azure proxy
tsh proxy azure
```

### tsh request

Just-in-Time (JIT) access requests for privilege elevation.

```bash
# Request elevated roles
tsh request create --roles=admin --reason="Deploy hotfix CVE-2024-1234"

# Request access to specific resource
tsh request create --resource=node/prod-db-01 --reason="Debug query"

# List pending requests
tsh request ls

# Show request details
tsh request show <request-id>

# Review/approve (if you're an approver)
tsh request review --approve <request-id>
```

Integrates with Slack, Teams, PagerDuty for approval workflows.

### tsh aws / gcloud / az

Execute cloud CLI commands with Teleport credentials.

```bash
# AWS (assumes role via Teleport)
tsh aws s3 ls
tsh aws ec2 describe-instances
tsh aws --aws-role=admin s3 ls s3://mybucket

# Google Cloud
tsh gcloud compute instances list
tsh gsutil ls gs://mybucket

# Azure
tsh az vm list
tsh az storage account list
```

Start local proxy for tools that don't support tsh wrapper:
```bash
tsh proxy aws -p 8888 &
export HTTPS_PROXY=http://localhost:8888
aws s3 ls  # Uses proxy
```

### tsh sessions

Manage and join active sessions.

```bash
# List active sessions
tsh sessions ls

# Join an active session (collaborative debugging)
tsh join <session-id>

# Play back recorded session
tsh play <session-id>
tsh play --speed=2x <session-id>     # 2x speed
tsh play --skip-idle-time <session-id>

# List recordings
tsh recordings ls
```

---

## Workflows

### Daily Login
```bash
# Morning login
tsh login --proxy=teleport.company.com

# Verify
tsh status

# List available nodes
tsh ls
```

### Deploy to Server
```bash
# Upload artifact
tsh scp ./build/app.tar.gz deploy@prod-01:/opt/app/

# SSH and deploy
tsh ssh deploy@prod-01 "cd /opt/app && tar xzf app.tar.gz && ./restart.sh"
```

### Fetch Logs
```bash
# Single file
tsh scp root@prod-01:/var/log/app/error.log ./

# Recent logs via SSH
tsh ssh root@prod-01 "journalctl -u myapp --since '1 hour ago'" > local-logs.txt
```

### Port Forward to Database
```bash
# Forward local 5432 to remote postgres
tsh ssh -L 5432:localhost:5432 -N root@db-server &

# Connect locally
psql -h localhost -U myuser mydb
```

### Multi-hop Access
```bash
# Login to leaf cluster through root
tsh login --proxy=root.example.com leaf-cluster

# SSH to node in leaf cluster
tsh ssh --cluster=leaf-cluster user@internal-node
```

---

## Node Discovery

```bash
# List all nodes
tsh ls

# Filter by label
tsh ls env=prod
tsh ls env=staging,role=api

# Show specific columns
tsh ls --format=json | jq '.[] | {name: .spec.hostname, addr: .spec.addr}'

# Clusters
tsh clusters
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Certificate expired | `tsh login --proxy=...` |
| Node not found | `tsh ls` to check available nodes |
| Permission denied | Check roles: `tsh status`, request access |
| Connection timeout | Check proxy address, network |
| Wrong cluster | `tsh logout && tsh login --proxy=correct` |

### Debug Mode
```bash
tsh ssh --debug user@hostname
tsh login --debug --proxy=teleport.example.com
```

### Request Access
```bash
# Request role elevation
tsh login --request-roles=admin --request-reason="Deploy hotfix"

# Check pending requests
tsh requests ls
```

---

## VNet (Virtual Network)

**FYI:** When VNet is running, you can access servers directly by hostname without `tsh ssh`.

```bash
# Instead of:
tsh ssh duke "curl http://localhost:8182/status"

# With VNet, access directly:
curl http://duke:8182/status

# Or in browser:
open http://duke:8182/
```

**When to use VNet vs tsh ssh:**
| Use Case | Method |
|----------|--------|
| HTTP requests to server | VNet: `curl http://hostname:port/` |
| Run shell commands | `tsh ssh user@hostname "command"` |
| Interactive shell | `tsh ssh user@hostname` |
| File copy | `tsh scp` (VNet doesn't help) |
| Database access | VNet or `tsh db connect` |

VNet creates a virtual network interface that routes traffic to Teleport-enrolled servers. Check if running: look for Teleport Connect app or `tsh vnet` process.

---

## Environment Variables

```bash
# Default proxy (skip --proxy flag)
export TELEPORT_PROXY=teleport.example.com

# Default user
export TELEPORT_USER=alice

# Default cluster
export TELEPORT_CLUSTER=prod

# Auth connector
export TELEPORT_AUTH=github

# Home directory (~/.tsh by default)
export TELEPORT_HOME=~/.tsh

# Debug mode
export TELEPORT_DEBUG=1

# Disable SSH agent integration
export TELEPORT_USE_LOCAL_SSH_AGENT=false

# Default MFA mode
export TELEPORT_MFA_MODE=sso
```

Add to `~/.zshrc` or `~/.bashrc` for persistence.

## Configuration Files

```
~/.tsh/                          # Teleport home directory
├── config/config.yaml           # User config
├── teleport.example.com/        # Per-proxy certificates
│   ├── certs.pem
│   └── keys/
└── environment                  # Env vars for SSH sessions

/etc/tsh.yaml                    # Global config (all users)
```

**User config example (~/.tsh/config/config.yaml):**
```yaml
# Custom headers for specific proxies
add_headers:
  - proxy: "teleport.example.com"
    headers:
      X-Custom-Header: "value"

# Command aliases
aliases:
  prod: "tsh ssh --cluster=prod root@$1"
```
