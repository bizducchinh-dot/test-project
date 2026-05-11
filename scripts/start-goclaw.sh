#!/usr/bin/env bash
set -euo pipefail

PORT="${GOCLAW_PORT:-18790}"
ENV_FILE="${HOME}/.goclaw/env"
LOG_FILE="${HOME}/.goclaw/server.log"
PG_DATA="/var/lib/postgresql/16/main"
PG_CONF="/etc/postgresql/16/main/postgresql.conf"
PG_BIN="/usr/lib/postgresql/16/bin"
READY_TIMEOUT_S="${GOCLAW_READY_TIMEOUT_S:-25}"

log() { printf '[start-goclaw] %s\n' "$*"; }

port_listening() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:${PORT}/health" 2>/dev/null
  else
    (exec 3<>"/dev/tcp/127.0.0.1/${PORT}") 2>/dev/null && exec 3>&-
  fi
}

postgres_up() {
  [ -f "${PG_DATA}/postmaster.pid" ] || return 1
  pg_pid=$(head -1 "${PG_DATA}/postmaster.pid" 2>/dev/null || true)
  [ -n "$pg_pid" ] && kill -0 "$pg_pid" 2>/dev/null
}

if port_listening; then
  log "gateway already listening on :${PORT}"
  exit 0
fi

if ! command -v goclaw >/dev/null 2>&1; then
  log "goclaw not installed; run scripts/install-goclaw.sh first" >&2
  exit 0
fi

if [ ! -f "$ENV_FILE" ]; then
  log "no env file at $ENV_FILE; run scripts/install-goclaw.sh first" >&2
  exit 0
fi

if [ -x "${PG_BIN}/pg_ctl" ] && ! postgres_up; then
  log "starting postgres cluster"
  sudo -u postgres "${PG_BIN}/pg_ctl" -D "$PG_DATA" -l /var/log/postgresql/start.log \
    -o "-c config_file=${PG_CONF}" start >/dev/null 2>&1 || \
    log "postgres pg_ctl returned non-zero (continuing)"
  sleep 2
fi

mkdir -p "$(dirname "$LOG_FILE")"
setsid nohup bash -c ". '$ENV_FILE' && exec goclaw" >>"$LOG_FILE" 2>&1 </dev/null &
disown || true

deadline=$(( $(date +%s) + READY_TIMEOUT_S ))
while [ "$(date +%s)" -lt "$deadline" ]; do
  if port_listening; then
    log "gateway ready on :${PORT}"
    exit 0
  fi
  sleep 0.5
done

log "gateway did not become ready within ${READY_TIMEOUT_S}s; tail ${LOG_FILE}" >&2
exit 0
