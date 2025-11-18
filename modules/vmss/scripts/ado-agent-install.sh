#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ============ GLOBAL CONFIG ============
AZDO_ORG_URL="https://dev.azure.com/achuthadevops25"
POOL_NAME="app-vmss"

AGENT_VERSION="4.264.2"
AGENT_USER="adodevagent"
AGENT_DIR="/opt/ado-agent"
WORK_DIR="${AGENT_DIR}/_work"

INSTALL_LOG="/var/log/ado-agent-install.log"
AGENT_CLEANUP_LOG="/var/log/ado-agent-cleanup.log"
OFFLINE_CLEANUP_LOG="/var/log/ado-offline-agent-cleanup.log"

PKG="vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz"
DOWNLOAD_URL="https://download.agent.dev.azure.com/agent/${AGENT_VERSION}/${PKG}"

PAT="D3340VTUM54JJXwFWFKDTBAWr2ZMm7PB8MEQ8p0NLWZ5xr9NACQ7JQQJ99BKACAAAAAAAAAAAAASAZDOwkZR"

log() { echo "$(date '+%F %T') [$1] ${2:-}" | tee -a "$INSTALL_LOG"; }
abort() { log ERROR "$1"; exit 1; }

retry() {
  local attempts="$1"; shift
  local delay="$1"; shift
  local cmd=("$@")
  local n=0
  until "${cmd[@]}"; do
    n=$((n+1))
    if [[ $n -ge $attempts ]]; then return 1; fi
    sleep "$delay"
  done
}

auth_header() {
  local auth_b64
  auth_b64=$(printf ':%s' "$PAT" | base64 | tr -d '\n')
  printf 'Authorization: Basic %s' "$auth_b64"
}

curl_ado() {
  curl --http1.1 -sS "$@"
}

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root (sudo)." >&2
  exit 1
fi

# 1) INSTALL & REGISTER AGENT ON THIS VM
log INFO "Starting ADO agent install. Pool='${POOL_NAME}', Org='${AZDO_ORG_URL}'"

export DEBIAN_FRONTEND=noninteractive

log INFO "Waiting for network and DNS..."
retry 10 3 getent hosts dev.azure.com >/dev/null || abort "DNS resolution failed for dev.azure.com"
retry 10 3 getent hosts download.agent.dev.azure.com >/dev/null || abort "DNS resolution failed for download.agent.dev.azure.com"

log INFO "Installing required packages (curl, jq, tar)..."
retry 3 5 apt-get update -y >>"$INSTALL_LOG" 2>&1 || abort "apt-get update failed"
retry 3 5 apt-get install -y curl jq tar >>"$INSTALL_LOG" 2>&1 || abort "apt-get install failed"

for cmd in curl jq tar base64; do
  command -v "$cmd" >/dev/null 2>&1 || abort "$cmd missing"
done

log INFO "Ensuring agent user '${AGENT_USER}' and directory '${AGENT_DIR}' exist..."
if ! id -u "$AGENT_USER" &>/dev/null; then
  useradd --system -d "$AGENT_DIR" -s /bin/bash "$AGENT_USER"
fi

mkdir -p "$WORK_DIR"
chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_DIR"


cd "$AGENT_DIR"
if [[ ! -f "$PKG" ]]; then
  log INFO "Downloading ADO agent from ${DOWNLOAD_URL}..."
  retry 5 3 curl -sSL -o "$PKG" "$DOWNLOAD_URL" || abort "Agent download failed"
fi

log INFO "Extracting ADO agent..."
tar zxf "$PKG"
chown -R "$AGENT_USER:$AGENT_USER" "$AGENT_DIR"

NAME="$(hostname)"
log INFO "Configuring agent '${NAME}' for pool '${POOL_NAME}'..."

sudo -u "$AGENT_USER" ./config.sh --unattended \
  --agent "$NAME" \
  --url "$AZDO_ORG_URL" \
  --auth pat \
  --token "$PAT" \
  --pool "$POOL_NAME" \
  --work "$WORK_DIR" \
  --replace \
  --acceptTeeEula >>"$INSTALL_LOG" 2>&1 || abort "Agent config failed"

log INFO "Installing agent as service..."
./svc.sh install >>"$INSTALL_LOG" 2>&1 || abort "Service install failed"

log INFO "Starting agent service..."
./svc.sh start >>"$INSTALL_LOG" 2>&1 || abort "Service start failed"

# 2) PER-VM SHUTDOWN CLEANUP (REMOVE THIS AGENT)
log INFO "Installing per-VM agent cleanup script and systemd unit (on shutdown)..."

cat >/usr/local/bin/ado-agent-cleanup.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail
IFS=\$'\n\t'

LOG_FILE="${AGENT_CLEANUP_LOG}"
AGENT_DIR="${AGENT_DIR}"
AGENT_USER="${AGENT_USER}"
PAT="${PAT}"

log(){ echo "\$(date '+%F %T') [\$1] \${2:-}" | tee -a "\$LOG_FILE"; }

log INFO "Starting agent cleanup on shutdown..."

if [[ ! -d "\$AGENT_DIR" ]]; then
  log INFO "Agent directory '\$AGENT_DIR' not found; nothing to do."
  exit 0
fi

cd "\$AGENT_DIR"

log INFO "Stopping agent service..."
./svc.sh stop >>"\$LOG_FILE" 2>&1 || log WARN "Service stop failed (maybe already stopped)"

log INFO "Removing agent registration from Azure DevOps (as '\$AGENT_USER')..."
if ! sudo -u "\$AGENT_USER" ./config.sh remove --unattended --auth pat --token "\$PAT" >>"\$LOG_FILE" 2>&1; then
  log WARN "Agent remove failed – may already be removed or network down."
else
  log INFO "Agent successfully removed from Azure DevOps."
fi

log INFO "Agent cleanup completed."
exit 0
EOF

chmod +x /usr/local/bin/ado-agent-cleanup.sh

cat >/etc/systemd/system/ado-agent-cleanup.service <<'EOF'
[Unit]
Description=Azure DevOps Agent Cleanup on Shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target poweroff.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/usr/local/bin/ado-agent-cleanup.sh
TimeoutStopSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ado-agent-cleanup.service
systemctl start ado-agent-cleanup.service || true

log INFO "Per-VM shutdown cleanup installed."

# 3) OFFLINE AGENT CLEANER (POOL-WIDE) + CRON (EVERY 1 MIN)

log INFO "Installing pool-wide offline agent cleanup script and cron job..."

cat >/usr/local/bin/ado-offline-agent-cleaner.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail
IFS=\$'\n\t'

ORG_URL="${AZDO_ORG_URL}"
POOL_NAME="${POOL_NAME}"
PAT="${PAT}"

LOG_FILE="${OFFLINE_CLEANUP_LOG}"
AGENT_NAME_PREFIX="${POOL_NAME}"   # manage only agents whose name starts with this

log() { echo "\$(date '+%F %T') [\$1] \${2:-}" | tee -a "\$LOG_FILE"; }

auth_header() {
  local auth_b64
  auth_b64=\$(printf ':%s' "\$PAT" | base64 | tr -d '\n')
  printf 'Authorization: Basic %s' "\$auth_b64"
}

curl_ado() {
  curl --http1.1 -sS "\$@"
}

log INFO "Starting offline agent cleanup for pool '\$POOL_NAME'..."

for cmd in curl jq base64; do
  if ! command -v "\$cmd" >/dev/null 2>&1; then
    log ERROR "Missing required command: \$cmd"
    exit 1
  fi
done

# 1) Get pool ID by name
POOL_JSON=\$(curl_ado \
  -H "\$(auth_header)" \
  "\$ORG_URL/_apis/distributedtask/pools?poolName=\${POOL_NAME}&api-version=7.1-preview.1") || {
    log ERROR "Failed to query pool list from Azure DevOps"
    exit 1
  }

POOL_ID=\$(echo "\$POOL_JSON" | jq -r '.value[0].id')

if [[ -z "\$POOL_ID" || "\$POOL_ID" == "null" ]]; then
  log ERROR "Could not find pool '\$POOL_NAME' in org '\$ORG_URL'"
  log ERROR "Raw response: \$POOL_JSON"
  exit 1
fi

log INFO "Pool '\$POOL_NAME' resolved to id=\$POOL_ID"

# 2) Get agents in that pool
AGENTS_JSON=\$(curl_ado \
  -H "\$(auth_header)" \
  "\$ORG_URL/_apis/distributedtask/pools/\${POOL_ID}/agents?includeAssignedRequest=true&api-version=7.1-preview.1") || {
    log ERROR "Failed to fetch agents for pool id=\$POOL_ID"
    exit 1
  }

COUNT_DELETED=0
COUNT_SKIPPED=0

mapfile -t AGENTS < <(echo "\$AGENTS_JSON" | jq -c '.value[]')

for agent in "\${AGENTS[@]}"; do
  ID=\$(echo "\$agent"   | jq -r '.id')
  NAME=\$(echo "\$agent" | jq -r '.name')
  STATUS=\$(echo "\$agent" | jq -r '.status')
  ENABLED=\$(echo "\$agent" | jq -r '.enabled')

  if [[ -n "\$AGENT_NAME_PREFIX" && "\$NAME" != \${AGENT_NAME_PREFIX}* ]]; then
    log INFO "Skipping agent id=\$ID name=\$NAME (prefix mismatch)"
    COUNT_SKIPPED=\$((COUNT_SKIPPED+1))
    continue
  fi

  if [[ "\$ENABLED" == "true" && "\$STATUS" == "offline" ]]; then
    log INFO "Deleting offline agent id=\$ID name=\$NAME status=\$STATUS enabled=\$ENABLED"
    if curl_ado -X DELETE \
        -H "\$(auth_header)" \
        "\$ORG_URL/_apis/distributedtask/pools/\${POOL_ID}/agents/\${ID}?api-version=7.1-preview.1" \
        >/dev/null; then
      log INFO "Successfully deleted agent id=\$ID name=\$NAME"
      COUNT_DELETED=\$((COUNT_DELETED+1))
    else
      log ERROR "Failed to delete agent id=\$ID name=\$NAME"
    fi
  else
    log INFO "Keeping agent id=\$ID name=\$NAME status=\$STATUS enabled=\$ENABLED"
    COUNT_SKIPPED=\$((COUNT_SKIPPED+1))
  fi
done

log INFO "Cleanup run completed. Deleted=\$COUNT_DELETED, Skipped=\$COUNT_SKIPPED"
exit 0
EOF

chmod +x /usr/local/bin/ado-offline-agent-cleaner.sh

touch "$OFFLINE_CLEANUP_LOG"

# Install cron job for root: run every 1 minute
CRON_LINE="* * * * * /usr/bin/env bash /usr/local/bin/ado-offline-agent-cleaner.sh >> ${OFFLINE_CLEANUP_LOG} 2>&1"

( crontab -u root -l 2>/dev/null | grep -v 'ado-offline-agent-cleaner.sh' || true; echo "$CRON_LINE" ) | crontab -u root -

log INFO "Offline agent cleanup cron job installed in root crontab (every 1 minute)."

unset PAT
log INFO "Agent '${NAME}' installed, per-VM shutdown cleanup + pool-wide offline cleanup configured."
