#!/usr/bin/env bash
set -euo pipefail

# Only run inside Claude Code on the web (cloud VM).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

"${CLAUDE_PROJECT_DIR}/scripts/start-openclaw.sh" || true
