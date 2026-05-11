#!/usr/bin/env bash
set -euo pipefail

PORT="${OPENCLAW_PORT:-18789}"
GATEWAY_LOG="${HOME}/.openclaw/gateway.log"
READY_TIMEOUT_S="${OPENCLAW_READY_TIMEOUT_S:-20}"

log() { printf '[start-openclaw] %s\n' "$*"; }

port_listening() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS --max-time 2 -o /dev/null "http://127.0.0.1:${PORT}/__openclaw__/" 2>/dev/null
  else
    (exec 3<>"/dev/tcp/127.0.0.1/${PORT}") 2>/dev/null && exec 3>&-
  fi
}

if port_listening; then
  log "gateway already listening on :${PORT}"
  exit 0
fi

if ! command -v openclaw >/dev/null 2>&1; then
  log "openclaw not installed; run scripts/install-openclaw.sh first" >&2
  exit 0
fi

if [ ! -f "${HOME}/.openclaw/openclaw.json" ]; then
  log "no config at ~/.openclaw/openclaw.json; run scripts/install-openclaw.sh first" >&2
  exit 0
fi

mkdir -p "$(dirname "$GATEWAY_LOG")"

setsid nohup openclaw gateway run >>"$GATEWAY_LOG" 2>&1 </dev/null &
disown || true

deadline=$(( $(date +%s) + READY_TIMEOUT_S ))
while [ "$(date +%s)" -lt "$deadline" ]; do
  if port_listening; then
    log "gateway ready on :${PORT}"
    exit 0
  fi
  sleep 0.5
done

log "gateway did not become ready within ${READY_TIMEOUT_S}s; tail ${GATEWAY_LOG}" >&2
exit 0
