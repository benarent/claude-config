# tsh Command Reference

## Global Flags

| Flag | Description |
|------|-------------|
| `--proxy` | Teleport proxy address |
| `--user` | Teleport username |
| `--cluster` | Target cluster name |
| `--debug, -d` | Verbose debug output |
| `--insecure` | Skip TLS verification (dev only) |
| `--headless` | Headless authentication |
| `--identity` | Identity file path |
| `--jumphost, -J` | Jump host for proxying |
| `--no-use-local-ssh-agent` | Disable SSH agent |
| `--skip-version-check` | Skip version validation |

---

## tsh login

```
tsh login [flags] [cluster]
```

| Flag | Description | Example |
|------|-------------|---------|
| `--proxy` | Proxy address | `--proxy=teleport.example.com` |
| `--user` | Username | `--user=alice` |
| `--auth` | Auth connector | `--auth=github` |
| `--ttl` | Certificate TTL | `--ttl=8h` |
| `--request-roles` | Request roles | `--request-roles=admin` |
| `--request-reason` | Access reason | `--request-reason="deploy"` |
| `--browser` | Browser mode | `--browser=none` |
| `--headless` | Headless auth (CI/remote) | `--headless` |
| `--out` | Save cert to file | `--out=identity.pem` |
| `--format` | Cert format | `--format=openssh` |
| `--bind-addr` | Callback address | `--bind-addr=localhost:8080` |

**Auth connectors:**
- `local` — Username/password
- `github` — GitHub OAuth
- `saml` — SAML IdP
- `oidc` — OIDC provider

**Browser modes:**
- `default` — System browser
- `none` — Print URL only (headless)

---

## tsh ssh

```
tsh ssh [flags] [user@]host [command]
```

| Flag | Short | Description |
|------|-------|-------------|
| `--cluster` | `-c` | Target cluster |
| `--login` | `-l` | Remote username |
| `--port` | `-p` | SSH port |
| `--local-forward` | `-L` | Local port forward |
| `--remote-forward` | `-R` | Remote port forward |
| `--dynamic-forward` | `-D` | SOCKS proxy |
| `--forward-agent` | `-A` | Agent forwarding |
| `--no-remote-exec` | `-N` | No remote command |
| `--tty` | `-t` | Force TTY |
| `--option` | `-o` | SSH option |
| `--enable-escape-sequences` | | Enable ~. escape |

**Host formats:**
```bash
# By name
user@hostname

# By UUID
user@node-uuid

# By label (single)
user@env=prod

# By label (multiple)
user@env=prod,role=api

# Label with spaces
user@"name=web server"
```

**Port forwarding:**
```bash
# Local: access remote:8080 via localhost:8080
-L 8080:localhost:8080

# Local: access db-internal:5432 via remote
-L 5432:db-internal:5432

# Remote: expose local:3000 on remote:3000
-R 3000:localhost:3000

# SOCKS proxy
-D 1080
```

---

## tsh scp

```
tsh scp [flags] <source> <dest>
```

| Flag | Short | Description |
|------|-------|-------------|
| `--cluster` | `-c` | Target cluster |
| `--login` | `-l` | Remote username |
| `--port` | `-P` | SSH port |
| `--recursive` | `-r` | Copy directories |
| `--preserve` | `-p` | Preserve times/modes |
| `--quiet` | `-q` | Suppress progress |

**Path formats:**
```bash
# Local paths
./relative/path
/absolute/path
~/home/path

# Remote paths
user@host:/absolute/path
user@host:relative/path
user@host:~/home/path

# With labels
user@env=prod:/path
```

**Examples:**
```bash
# Upload
tsh scp file.txt user@host:/tmp/
tsh scp -r dir/ user@host:/opt/

# Download
tsh scp user@host:/var/log/app.log ./
tsh scp -r user@host:/etc/app/ ./config/

# Between clusters
tsh scp --cluster=staging user@host:/data.txt ./
tsh scp ./data.txt --cluster=prod user@host:/data/
```

---

## tsh ls

```
tsh ls [flags] [labels]
```

| Flag | Description |
|------|-------------|
| `--cluster` | Target cluster |
| `--format` | Output format (text, json, yaml) |
| `--all` | Show all nodes (including offline) |

**Label queries:**
```bash
tsh ls                      # All nodes
tsh ls env=prod             # Single label
tsh ls env=prod,role=web    # Multiple labels (AND)
tsh ls "env=prod or env=staging"  # OR query
```

---

## tsh status

```
tsh status [flags]
```

Shows:
- Logged-in user
- Cluster name
- Roles
- Certificate expiry
- Principals

---

## tsh logout

```
tsh logout [flags]
```

Removes cached certificates.

---

## tsh clusters

```
tsh clusters [flags]
```

Lists accessible clusters (root + leaf).

---

## tsh requests

```
tsh requests ls              # List pending
tsh requests show <id>       # Show details
tsh requests create --roles=admin --reason="deploy"
tsh request review --approve <id>
```

---

## tsh db

```
tsh db ls                    # List databases
tsh db login <database>      # Get credentials
tsh db logout <database>     # Remove credentials
tsh db connect <database>    # Direct connection
tsh db exec <query>          # Execute query
tsh db env                   # Print env vars
tsh db config                # Connection info for GUI
```

| Flag | Description |
|------|-------------|
| `--db-user` | Database username |
| `--db-name` | Database name |
| `--db-roles` | Auto-provision roles |
| `--tunnel` | Enable tunnel mode |
| `-p, --port` | Local proxy port |

---

## tsh kube

```
tsh kube ls                  # List clusters
tsh kube login <cluster>     # Authenticate (configures kubectl)
tsh kube logout              # Remove credentials
tsh proxy kube <cluster>     # Start local proxy
```

| Flag | Description |
|------|-------------|
| `--cluster` | Target cluster |
| `--as` | Impersonate user |
| `-p, --port` | Local proxy port |

---

## tsh apps

```
tsh apps ls                  # List applications
tsh apps login <app>         # Get certificate
tsh apps logout <app>        # Remove credentials
tsh apps config              # Print cert paths
tsh proxy app <app>          # Start local proxy
```

| Flag | Description |
|------|-------------|
| `--format` | Config output (uri, ca, cert, key, curl) |
| `-p, --port` | Local proxy port |

---

## tsh proxy

```
tsh proxy ssh <user@host>    # SSH proxy (OpenSSH integration)
tsh proxy db <database>      # Database proxy
tsh proxy kube <cluster>     # Kubernetes proxy
tsh proxy app <app>          # Application proxy
tsh proxy aws                # AWS API proxy
tsh proxy gcloud             # Google Cloud proxy
tsh proxy azure              # Azure CLI proxy
```

| Flag | Description |
|------|-------------|
| `-p, --port` | Local bind port |
| `--db-user` | Database user (for db) |
| `--db-name` | Database name (for db) |
| `--tunnel` | Tunnel mode (for db) |

---

## tsh aws / gcloud / az

```
tsh aws <command>            # Run AWS CLI
tsh aws --aws-role=<role>    # Assume specific role
tsh gcloud <command>         # Run gcloud
tsh gsutil <command>         # Run gsutil
tsh az <command>             # Run Azure CLI
```

---

## tsh sessions

```
tsh sessions ls              # List active sessions
tsh join <session-id>        # Join session
tsh play <session-id>        # Playback recording
tsh recordings ls            # List recordings
```

| Flag | Description |
|------|-------------|
| `--speed` | Playback speed (0.5x, 1x, 2x, 4x, 8x) |
| `--skip-idle-time` | Skip inactive periods |
| `--format` | Output format (pty, json, yaml) |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Connection failed |
| 3 | Authentication failed |
| 4 | Permission denied |
| 5 | Node not found |
