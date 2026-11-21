FROM nousresearch/hermes-agent:v0.23.3@sha256:3e9fe4c6ef36490f43aa0d0d80f9df64e9c92a576eee3042f1a97c8813c05355

LABEL org.opencontainers.image.source="https://github.com/erobert-c/hermes-op" \
      org.opencontainers.image.description="Nous Hermes Agent with the 1Password CLI (op) and Claude Code"

COPY --from=1password/op:2.42.0@sha256:b0d7eebcb09bdc9d5862af91533e1851c968d4f969270c906f5da8c574f87e93 /usr/local/bin/op /usr/local/bin/op

# Extra Python packages for Hermes plugins, installed into the (sealed) hermes
# venv at build time so they survive container recreation.
COPY requirements.txt /tmp/requirements.txt
RUN --mount=from=ghcr.io/astral-sh/uv:0.13.9@sha256:d3b601f0c7b118bc1753febf7c41cc80981df678445e0254284eecf84db79a7d,source=/uv,target=/usr/local/bin/uv \
    uv pip install --python /opt/hermes/.venv/bin/python --no-cache -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Claude Code CLI. The base image already ships node/npm (in /usr/local/bin), git
# and openssh-client. Installed under /usr/local so `claude` lands on PATH.
# renovate: datasource=npm depName=@anthropic-ai/claude-code
ARG CLAUDE_CODE_VERSION=2.1.330
# Newer npm blocks dependency install scripts by default; the package needs its
# postinstall to replace the bin stub with the native binary, hence --allow-scripts.
# `claude --version` fails the build if the stub is still in place.
RUN npm install -g --prefix /usr/local --no-audit --no-fund \
        --allow-scripts=@anthropic-ai/claude-code \
        @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && claude --version \
    && npm cache clean --force

# Keep Claude's login/state inside the mounted Hermes volume so it survives
# container recreation (credentials + .claude.json both live in this dir).
ENV CLAUDE_CONFIG_DIR=/opt/data/claude
