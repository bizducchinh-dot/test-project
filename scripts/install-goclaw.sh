#!/usr/bin/env bash
set -euo pipefail

# Bootstrap GoClaw v3.11.3 on a fresh Linux amd64 host.
# Required env: GEMINI_API_KEY (or pass as first positional arg).

KEY="${GEMINI_API_KEY:-${1:-}}"
VERSION="${GOCLAW_VERSION:-3.11.3}"
PG_USER="${GOCLAW_PG_USER:-goclaw}"
PG_PASS="${GOCLAW_PG_PASS:-goclaw_local_password}"
PG_DB="${GOCLAW_PG_DB:-goclaw}"
TENANT_ID="${GOCLAW_TENANT_ID:-0193a5b0-7000-7000-8000-000000000001}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '[install-goclaw] %s\n' "$*"; }

[ -n "$KEY" ] || die "GEMINI_API_KEY not set. Get one at https://aistudio.google.com/apikey"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *) die "Unsupported arch: $ARCH" ;;
esac

if ! command -v goclaw >/dev/null 2>&1; then
  log "downloading goclaw v${VERSION} ${ARCH}"
  TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
  curl -fL --max-time 120 -o "$TMP/goclaw.tar.gz" \
    "https://github.com/nextlevelbuilder/goclaw/releases/download/v${VERSION}/goclaw-${VERSION}-linux-${ARCH}.tar.gz"
  mkdir -p /opt/goclaw/migrations
  tar -xzf "$TMP/goclaw.tar.gz" -C /opt/goclaw
  mv /opt/goclaw/*.sql /opt/goclaw/migrations/ 2>/dev/null || true
  ln -sf /opt/goclaw/goclaw /usr/local/bin/goclaw
fi

if ! command -v psql >/dev/null 2>&1; then
  log "installing postgresql + pgvector"
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postgresql postgresql-16-pgvector >/dev/null
fi

PG_DATA=/var/lib/postgresql/16/main
PG_CONF=/etc/postgresql/16/main/postgresql.conf
PG_BIN=/usr/lib/postgresql/16/bin

if [ ! -f "${PG_DATA}/postmaster.pid" ] || ! kill -0 "$(head -1 ${PG_DATA}/postmaster.pid 2>/dev/null)" 2>/dev/null; then
  log "starting postgres"
  sudo -u postgres "${PG_BIN}/pg_ctl" -D "$PG_DATA" -l /var/log/postgresql/start.log \
    -o "-c config_file=${PG_CONF}" start >/dev/null
  sleep 2
fi

log "creating role + database (idempotent)"
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${PG_USER}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE ROLE ${PG_USER} LOGIN PASSWORD '${PG_PASS}';" >/dev/null
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${PG_DB}'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${PG_DB} OWNER ${PG_USER};" >/dev/null
sudo -u postgres psql -d "${PG_DB}" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null

DSN="postgres://${PG_USER}:${PG_PASS}@127.0.0.1:5432/${PG_DB}?sslmode=disable"

mkdir -p "${HOME}/.goclaw"
if [ ! -f "${HOME}/.goclaw/env" ]; then
  log "writing ${HOME}/.goclaw/env"
  ENCKEY=$(openssl rand -base64 32)
  umask 077
  cat > "${HOME}/.goclaw/env" <<EOF
export GOCLAW_POSTGRES_DSN="${DSN}"
export GOCLAW_ENCRYPTION_KEY="${ENCKEY}"
export GEMINI_API_KEY="${KEY}"
EOF
fi

log "running migrations"
. "${HOME}/.goclaw/env"
CURRENT=$(goclaw migrate version --migrations-dir /opt/goclaw/migrations 2>&1 | awk -F: '/version/ {gsub(/[^0-9]/,"",$2); print $2; exit}')
if [ -z "${CURRENT:-}" ] || [ "$CURRENT" = "0" ]; then
  goclaw migrate up --migrations-dir /opt/goclaw/migrations >/dev/null
fi

# Start gateway in background if not already up
if ! curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:18790/health" 2>/dev/null; then
  log "starting goclaw gateway"
  setsid nohup bash -c ". '${HOME}/.goclaw/env' && exec goclaw" \
    > "${HOME}/.goclaw/server.log" 2>&1 </dev/null &
  disown || true
  for _ in $(seq 1 40); do
    curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:18790/health" 2>/dev/null && break
    sleep 0.5
  done
fi

# Register Gemini provider via REST (idempotent — gateway encrypts the key)
if ! curl -fsS "http://127.0.0.1:18790/v1/providers" 2>/dev/null | grep -q '"name":"gemini"'; then
  log "registering Gemini provider"
  curl -sX POST "http://127.0.0.1:18790/v1/providers" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"gemini\",\"provider_type\":\"gemini_native\",\"api_key\":\"${KEY}\",\"api_base\":\"https://generativelanguage.googleapis.com/v1beta\",\"enabled\":true}" >/dev/null
fi

log "done. Verify: . ${HOME}/.goclaw/env && goclaw doctor"
