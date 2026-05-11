#!/usr/bin/env bash
# Install GoClaw v3.11.3 on a local Ubuntu (e.g. WSL2 on Windows).
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/bizducchinh-dot/test-project/claude/install-openclaw-uoTkh/scripts/install-goclaw-wsl.sh | bash -s -- AIzaSy_your_gemini_key
#   # or:  GEMINI_API_KEY=AIzaSy... bash install-goclaw-wsl.sh

set -euo pipefail

KEY="${GEMINI_API_KEY:-${1:-}}"
VERSION="${GOCLAW_VERSION:-3.11.3}"
PG_DB="${GOCLAW_PG_DB:-goclaw}"
PG_USER="${GOCLAW_PG_USER:-goclaw}"
PG_PASS="${GOCLAW_PG_PASS:-$(openssl rand -hex 16)}"

die() { printf '\e[31mERROR:\e[0m %s\n' "$*" >&2; exit 1; }
log() { printf '\e[36m[install-goclaw]\e[0m %s\n' "$*"; }

[ -n "$KEY" ] || die "Pass your Gemini API key as the first argument or set GEMINI_API_KEY env var. Get one at https://aistudio.google.com/apikey"

# 1. Confirm Linux amd64
[ "$(uname -s)" = "Linux" ] || die "This script is for Linux (incl. WSL2). Detected: $(uname -s)"
case "$(uname -m)" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; *) die "Unsupported arch" ;; esac

# 2. Need sudo for apt + writing /usr/local/bin
if [ "$EUID" -ne 0 ]; then SUDO="sudo"; else SUDO=""; fi
$SUDO -v || die "sudo required (will prompt for your password)"

log "installing dependencies (postgres, pgvector, curl)"
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -qq
$SUDO apt-get install -y --no-install-recommends \
  curl ca-certificates openssl postgresql postgresql-contrib >/dev/null

PG_MAJOR=$($SUDO -u postgres psql -tAc "SHOW server_version_num;" | sed 's/\(..\).*/\1/')
log "postgres major version: ${PG_MAJOR}"
$SUDO apt-get install -y --no-install-recommends "postgresql-${PG_MAJOR}-pgvector" >/dev/null \
  || die "pgvector not available for postgresql-${PG_MAJOR}. Try upgrading Ubuntu (recommend 24.04)."

# 3. Start postgres (works on both WSL with/without systemd)
if pgrep -x postgres >/dev/null 2>&1; then
  log "postgres already running"
else
  log "starting postgres"
  $SUDO service postgresql start >/dev/null
fi

# 4. Create DB role + database (idempotent)
log "configuring database"
$SUDO -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${PG_USER}'" | grep -q 1 || \
  $SUDO -u postgres psql -c "CREATE ROLE ${PG_USER} LOGIN PASSWORD '${PG_PASS}';" >/dev/null
$SUDO -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${PG_DB}'" | grep -q 1 || \
  $SUDO -u postgres psql -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};" >/dev/null
$SUDO -u postgres psql -d "${PG_DB}" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null

# 5. Download goclaw binary
if ! command -v goclaw >/dev/null 2>&1; then
  log "downloading goclaw v${VERSION} ${ARCH}"
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  curl -fL --max-time 180 -o "$TMP/goclaw.tar.gz" \
    "https://github.com/nextlevelbuilder/goclaw/releases/download/v${VERSION}/goclaw-${VERSION}-linux-${ARCH}.tar.gz"
  $SUDO mkdir -p /opt/goclaw/migrations
  $SUDO tar -xzf "$TMP/goclaw.tar.gz" -C /opt/goclaw
  $SUDO sh -c 'mv /opt/goclaw/*.sql /opt/goclaw/migrations/ 2>/dev/null || true'
  $SUDO ln -sf /opt/goclaw/goclaw /usr/local/bin/goclaw
fi

# 6. Write env file with DSN, encryption key, gateway token, gemini key
mkdir -p "${HOME}/.goclaw"
chmod 700 "${HOME}/.goclaw"
if [ ! -f "${HOME}/.goclaw/env" ]; then
  log "writing ${HOME}/.goclaw/env"
  ENCKEY=$(openssl rand -base64 32)
  GW_TOKEN=$(openssl rand -hex 24)
  cat > "${HOME}/.goclaw/env" <<EOF
export GOCLAW_POSTGRES_DSN="postgres://${PG_USER}:${PG_PASS}@127.0.0.1:5432/${PG_DB}?sslmode=disable"
export GOCLAW_ENCRYPTION_KEY="${ENCKEY}"
export GOCLAW_GATEWAY_TOKEN="${GW_TOKEN}"
export GEMINI_API_KEY="${KEY}"
EOF
  chmod 600 "${HOME}/.goclaw/env"
fi

# 7. Run migrations
log "running migrations"
# shellcheck disable=SC1091
. "${HOME}/.goclaw/env"
CURRENT=$(goclaw migrate version --migrations-dir /opt/goclaw/migrations 2>&1 | awk -F: '/version/ {gsub(/[^0-9]/,"",$2); print $2; exit}')
if [ -z "${CURRENT:-}" ] || [ "$CURRENT" = "0" ]; then
  goclaw migrate up --migrations-dir /opt/goclaw/migrations >/dev/null
fi

# 8. Start gateway in background
if curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:18790/health" 2>/dev/null; then
  log "goclaw already running"
else
  log "starting goclaw gateway"
  setsid nohup bash -c ". '${HOME}/.goclaw/env' && exec goclaw" \
    > "${HOME}/.goclaw/server.log" 2>&1 </dev/null &
  disown || true
  for _ in $(seq 1 40); do
    curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:18790/health" 2>/dev/null && break
    sleep 0.5
  done
fi

# 9. Register Gemini provider via REST (gateway encrypts the key with aes-gcm before storing)
if ! curl -fsS "http://127.0.0.1:18790/v1/providers" \
     -H "Authorization: Bearer ${GOCLAW_GATEWAY_TOKEN}" 2>/dev/null | grep -q '"name":"gemini"'; then
  log "registering Gemini provider"
  curl -sX POST "http://127.0.0.1:18790/v1/providers" \
    -H "Authorization: Bearer ${GOCLAW_GATEWAY_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"gemini\",\"provider_type\":\"gemini_native\",\"api_key\":\"${KEY}\",\"api_base\":\"https://generativelanguage.googleapis.com/v1beta\",\"enabled\":true}" >/dev/null
fi

# 10. Final summary
cat <<EOF

  ============================================================
  GoClaw v${VERSION} is ready.

  Open in your browser:    http://localhost:18790/
  User ID:                 system
  Gateway Token:           ${GOCLAW_GATEWAY_TOKEN}

  (token saved to ${HOME}/.goclaw/env — chmod 600)

  CLI verification:
    . ~/.goclaw/env && goclaw doctor

  Restart later (after reboot / wsl shutdown):
    . ~/.goclaw/env && setsid nohup goclaw > ~/.goclaw/server.log 2>&1 &
  ============================================================

EOF
