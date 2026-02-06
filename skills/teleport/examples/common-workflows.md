# Common Teleport Workflows

## Initial Setup

### First-time Login
```bash
# Login via SSO (opens browser)
tsh login --proxy=teleport.company.com

# Verify connection
tsh status

# List available nodes
tsh ls
```

### Configure Shell
```bash
# Add to ~/.zshrc or ~/.bashrc
export TELEPORT_PROXY=teleport.company.com
export TELEPORT_USER=myusername

# Now just:
tsh login
```

### Headless Login (CI/CD, Remote Machines)
```bash
# On remote machine without browser
tsh login --proxy=teleport.company.com --headless

# Prints URL - approve on another device with browser
# After approval, session is active on remote machine

# Alternative: browser=none prints URL only
tsh login --proxy=teleport.company.com --browser=none
```

### Machine Identity (Bot/Service Account)
```bash
# Export identity for automation
tsh login --proxy=teleport.company.com --out=identity.pem --ttl=8h

# Use identity in scripts
tsh --identity=identity.pem ssh root@server "run-backup.sh"
```

---

## SSH Workflows

### Interactive Session
```bash
# Connect to node
tsh ssh root@web-01

# With specific cluster
tsh ssh --cluster=prod root@web-01
```

### Run Single Command
```bash
# Check uptime
tsh ssh root@web-01 "uptime"

# View logs
tsh ssh root@web-01 "tail -100 /var/log/app/error.log"

# Check service status
tsh ssh root@web-01 "systemctl status myapp"
```

### Batch Commands Across Nodes
```bash
# Get uptime from all prod nodes
for node in $(tsh ls env=prod --format=json | jq -r '.[].spec.hostname'); do
  echo "=== $node ==="
  tsh ssh root@$node "uptime"
done
```

### Port Forwarding

```bash
# Access remote web app locally
tsh ssh -L 8080:localhost:8080 root@web-01
# Visit http://localhost:8080

# Database access
tsh ssh -L 5432:localhost:5432 -N root@db-01 &
psql -h localhost -U myuser mydb

# Redis
tsh ssh -L 6379:localhost:6379 -N root@redis-01 &
redis-cli

# Multiple forwards
tsh ssh -L 3000:localhost:3000 -L 5432:localhost:5432 root@server
```

### SOCKS Proxy
```bash
# Start proxy
tsh ssh -D 1080 -N root@jump-host &

# Configure browser or CLI to use localhost:1080
curl --socks5 localhost:1080 http://internal-service.local
```

---

## File Transfer Workflows

### Upload Deployment Artifact
```bash
# Single file
tsh scp ./build/app.tar.gz deploy@prod-01:/opt/app/

# Directory
tsh scp -r ./dist/ deploy@prod-01:/var/www/html/
```

### Download Logs
```bash
# Single file
tsh scp root@prod-01:/var/log/app/error.log ./logs/

# Directory of logs
tsh scp -r root@prod-01:/var/log/app/ ./logs/prod-01/

# Multiple nodes
for node in web-01 web-02 web-03; do
  mkdir -p ./logs/$node
  tsh scp root@$node:/var/log/app/error.log ./logs/$node/
done
```

### Backup Config
```bash
# Download config
tsh scp -r root@prod-01:/etc/myapp/ ./backup/config/

# Preserve permissions
tsh scp -rp root@prod-01:/etc/myapp/ ./backup/config/
```

### Stream Logs via SSH
```bash
# More flexible than scp for large logs
tsh ssh root@prod-01 "cat /var/log/app/error.log" > ./error.log

# Compressed transfer
tsh ssh root@prod-01 "gzip -c /var/log/app/error.log" > ./error.log.gz

# Filtered
tsh ssh root@prod-01 "grep ERROR /var/log/app/error.log" > ./errors.txt
```

---

## Multi-Cluster Workflows

### Switch Clusters
```bash
# Login to root cluster first
tsh login --proxy=teleport.company.com

# List available clusters
tsh clusters

# Login to leaf cluster
tsh login leaf-cluster

# Or SSH directly to leaf cluster node
tsh ssh --cluster=leaf-cluster root@internal-node
```

### Cross-Cluster File Transfer
```bash
# Download from prod cluster
tsh scp --cluster=prod root@db-01:/backup/dump.sql ./

# Upload to staging cluster
tsh scp --cluster=staging ./dump.sql root@db-01:/import/
```

---

## Database Access Workflows

### Connect to PostgreSQL
```bash
# List available databases
tsh db ls

# Login (get credentials)
tsh db login mypostgres

# Connect directly via psql
tsh db connect --db-user=admin --db-name=appdb mypostgres

# Or start proxy for GUI tools (DBeaver, pgAdmin)
tsh proxy db --db-user=admin --db-name=appdb -p 5432 mypostgres &
psql -h localhost -p 5432 -U admin appdb
```

### Connect to MySQL
```bash
tsh db login mymysql
tsh db connect --db-user=root --db-name=myapp mymysql
```

### Connect to MongoDB
```bash
tsh db login mymongo
tsh db connect --db-user=admin mymongo

# Or via proxy
tsh proxy db -p 27017 mymongo &
mongosh --host localhost --port 27017
```

### Run Query Across Multiple Databases
```bash
tsh db exec --dbs=db1,db2 --parallel "SELECT version();"
```

---

## Kubernetes Access Workflows

### Access Kubernetes Cluster
```bash
# List available clusters
tsh kube ls

# Login to cluster (configures kubectl automatically)
tsh kube login prod-k8s

# Now use kubectl normally
kubectl get pods -n myapp
kubectl logs -f deployment/api
kubectl exec -it pod/debug -- /bin/bash
```

### Switch Between Clusters
```bash
tsh kube login staging-k8s
kubectl get nodes

tsh kube login prod-k8s
kubectl get nodes
```

### Start Local Proxy (for tools that need kubeconfig)
```bash
tsh proxy kube prod-k8s -p 8443 &
# Configure tools to use localhost:8443
```

---

## Application Access Workflows

### Access Web Application
```bash
# List available apps
tsh apps ls

# Login to app
tsh apps login grafana

# Start local proxy
tsh proxy app grafana -p 3000
# Access at http://localhost:3000
```

### Access with curl
```bash
tsh apps login internal-api

# Get connection info
tsh apps config --format=uri      # https://internal-api.teleport.example.com
tsh apps config --format=curl     # Full curl command with certs

# Use certificates directly
curl --cacert $(tsh apps config --format=ca) \
     --cert $(tsh apps config --format=cert) \
     --key $(tsh apps config --format=key) \
     https://internal-api.teleport.example.com/health
```

---

## Cloud CLI Workflows

### AWS Access
```bash
# Run AWS CLI commands through Teleport
tsh aws s3 ls
tsh aws ec2 describe-instances --region us-west-2
tsh aws sts get-caller-identity

# Assume specific role
tsh aws --aws-role=prod-admin s3 ls s3://prod-bucket/

# Start local proxy for SDK/terraform
tsh proxy aws -p 8888 &
export HTTPS_PROXY=http://localhost:8888
terraform plan
```

### Google Cloud Access
```bash
tsh gcloud compute instances list
tsh gcloud container clusters list
tsh gsutil ls gs://my-bucket/
```

### Azure Access
```bash
tsh az vm list
tsh az storage account list
tsh az aks list
```

---

## Session Management

### Join a Colleague's Session
```bash
# List active sessions
tsh sessions ls

# Join by session ID (collaborative debugging)
tsh join a1b2c3d4-...
```

### Review Session Recordings
```bash
# List recordings
tsh recordings ls

# Play back a session
tsh play <session-id>

# Speed up playback
tsh play --speed=4x <session-id>

# Skip idle time
tsh play --skip-idle-time <session-id>
```

---

## Access Request Workflows

### Request Elevated Access
```bash
# Request admin role
tsh login --request-roles=admin --request-reason="Emergency hotfix for CVE-2024-1234"

# Check request status
tsh requests ls

# After approval, roles are active
tsh status  # Shows new roles
```

### Request Access to Specific Node
```bash
tsh request create --resource=node/prod-db-01 --reason="Debug query performance"
```

---

## Debugging

### Connection Issues
```bash
# Debug mode
tsh ssh --debug root@problematic-node

# Check certificate
tsh status

# Re-login if expired
tsh login
```

### Node Not Found
```bash
# List all nodes
tsh ls

# Check specific label
tsh ls env=prod

# Try with cluster flag
tsh ls --cluster=prod-cluster
```

### Permission Denied
```bash
# Check current roles
tsh status

# Request additional roles
tsh login --request-roles=developer --request-reason="Need access to dev servers"
```

---

## Integration with Claude Code

### Fetch Remote Logs for Analysis
```bash
# Fetch and analyze with log-analyze skill
tsh ssh root@prod-01 "journalctl -u myapp --since '2 hours ago'" > /tmp/app-logs.txt
/log-analyze /tmp/app-logs.txt --mode error-triage
```

### Deploy Script
```bash
# Upload, extract, restart
tsh scp ./release.tar.gz deploy@prod-01:/opt/app/ && \
tsh ssh deploy@prod-01 "cd /opt/app && tar xzf release.tar.gz && ./restart.sh"
```

### Health Check
```bash
# Quick cluster health
echo "=== Cluster Status ==="
tsh status
echo ""
echo "=== Available Nodes ==="
tsh ls
echo ""
echo "=== Node Count by Environment ==="
tsh ls --format=json | jq 'group_by(.metadata.labels.env) | map({env: .[0].metadata.labels.env, count: length})'
```
