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

USER node

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh", "lark-mcp"]

CMD ["--help"]
