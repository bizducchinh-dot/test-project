#!/usr/bin/env bash
set -euo pipefail

# Bootstrap OpenClaw on a fresh VM/host.
# Required env: GEMINI_API_KEY (or pass as first positional arg).
# Optional env: OPENCLAW_PRIMARY_MODEL (default: google/gemini-2.5-flash)

KEY="${GEMINI_API_KEY:-${1:-}}"
PRIMARY_MODEL="${OPENCLAW_PRIMARY_MODEL:-google/gemini-2.5-flash}"

die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '[install-openclaw] %s\n' "$*"; }

if [ -z "$KEY" ]; then
  cat >&2 <<'EOF'
ERROR: GEMINI_API_KEY is not set.

  Get a free key (no credit card) at https://aistudio.google.com/apikey
  Then run one of:
    GEMINI_API_KEY=AIza... bash scripts/install-openclaw.sh
    bash scripts/install-openclaw.sh AIza...
EOF
  exit 1
fi

command -v node >/dev/null 2>&1 || die "Node.js not found; install Node 22+ first."
NODE_MAJOR=$(node --version | sed -E 's/^v([0-9]+).*/\1/')
[ "$NODE_MAJOR" -ge 22 ] || die "Node 22+ required (found v${NODE_MAJOR})."
command -v npm >/dev/null 2>&1 || die "npm not found."

if ! command -v openclaw >/dev/null 2>&1; then
  log "installing openclaw via npm"
  npm install -g openclaw@latest >/dev/null
fi

if [ ! -f "${HOME}/.openclaw/openclaw.json" ]; then
  log "running onboard"
  openclaw onboard --non-interactive --accept-risk --auth-choice skip >/dev/null
fi

log "applying provider config (model=${PRIMARY_MODEL})"
PATCH=$(mktemp)
trap 'rm -f "$PATCH"' EXIT
cat >"$PATCH" <<EOF
{
  "env": { "vars": { "GEMINI_API_KEY": "${KEY}" } },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${PRIMARY_MODEL}",
        "fallbacks": [
          "google/gemini-2.5-flash-lite",
          "google/gemini-2.0-flash",
          "google/gemini-2.0-flash-lite"
        ],
        "timeoutMs": 60000
      }
    }
  },
  "logging": { "level": "warn" }
}
EOF
openclaw config patch --file "$PATCH" >/dev/null

log "disabling unused skills"
openclaw doctor --fix >/dev/null 2>&1 || true
openclaw sessions cleanup --fix-missing --enforce >/dev/null 2>&1 || true

log "done. Launch the gateway: scripts/start-openclaw.sh"
