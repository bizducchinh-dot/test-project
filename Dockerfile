# syntax=docker/dockerfile:1

FROM node:20-bookworm-slim

ENV NODE_ENV=production \
    XDG_RUNTIME_DIR=/home/node/.xdg/runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libsecret-1-0 \
    libsecret-tools \
    libglib2.0-bin \
    gnome-keyring \
    dbus \
    dbus-x11 \
    ca-certificates \
    python3 \
    make \
    g++ \
    pkg-config \
    libsecret-1-dev \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g @larksuiteoapi/lark-mcp@latest \
  && npm cache clean --force

RUN mkdir -p ${XDG_RUNTIME_DIR} \
  && mkdir -p /home/node/.local/state /home/node/.local/share/lark-mcp \
  && chown -R node:node ${XDG_RUNTIME_DIR} /home/node/.local

RUN <<'EOF'
cat >/usr/local/bin/docker-entrypoint.sh <<'SCRIPT'
#!/usr/bin/env bash
set -e
if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
  mkdir -p "${XDG_RUNTIME_DIR}"
  dbus-daemon --session --address="unix:path=${XDG_RUNTIME_DIR}/bus" --fork
  export DBUS_SESSION_BUS_ADDRESS="unix:path=${XDG_RUNTIME_DIR}/bus"
fi
mkdir -p "${XDG_RUNTIME_DIR}/keyring"
mkdir -p "${HOME}/.local/share/keyrings"
chmod 0700 "${XDG_RUNTIME_DIR}/keyring"
chmod 0700 "${HOME}/.local/share/keyrings"
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
  pkill -f gnome-keyring 2>/dev/null || true
  sleep 0.5
  current_ts="$(date +%s)"
  cat > "${HOME}/.local/share/keyrings/login.keyring" <<KEYRING_EOF
[keyring]
display-name=Login
ctime=${current_ts}
mtime=${current_ts}
lock-on-idle=false
lock-after=false
KEYRING_EOF
  chmod 0600 "${HOME}/.local/share/keyrings/login.keyring"
  eval $(gnome-keyring-daemon --start --daemonize --components=secrets --control-directory="${XDG_RUNTIME_DIR}/keyring" 2>/dev/null)
  for i in {1..50}; do
    if [[ -S "${XDG_RUNTIME_DIR}/keyring/control" ]] && gdbus introspect --session --dest org.freedesktop.secrets --object-path /org/freedesktop/secrets >/dev/null 2>&1; then
      break
    fi
    sleep 0.1
  done
  export GNOME_KEYRING_CONTROL="${XDG_RUNTIME_DIR}/keyring"
  if gdbus introspect --session --dest org.freedesktop.secrets --object-path /org/freedesktop/secrets >/dev/null 2>&1; then
    printf "" | gdbus call --session \
      --dest org.freedesktop.secrets \
      --object-path /org/freedesktop/secrets \
      --method org.freedesktop.secrets.Service.CreateCollection \
      "{'org.freedesktop.Secret.Collection.Label': <'login'>}" \
      "login" >/dev/null 2>&1 || true
    gdbus call --session \
      --dest org.freedesktop.secrets \
      --object-path /org/freedesktop/secrets \
      --method org.freedesktop.secrets.Service.SetAlias \
      "login" "/org/freedesktop/secrets/collection/login" >/dev/null 2>&1 || true
  fi
fi
exec "$@" 2> >(grep -v "couldn't access control socket\|discover_other_daemon" >&2)
SCRIPT
chmod +x /usr/local/bin/docker-entrypoint.sh
EOF

USER node

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "lark-mcp"]

CMD ["--help"]
