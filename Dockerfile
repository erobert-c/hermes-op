FROM nousresearch/hermes-agent:v0.23.3@sha256:3e9fe4c6ef36490f43aa0d0d80f9df64e9c92a576eee3042f1a97c8813c05355

LABEL org.opencontainers.image.source="https://github.com/erobert-c/hermes-op" \
      org.opencontainers.image.description="Nous Hermes Agent with the 1Password CLI (op), Claude Code and dev tools (gh, jq, shellcheck, uv, Go)"

COPY --from=1password/op:2.42.0@sha256:b0d7eebcb09bdc9d5862af91533e1851c968d4f969270c906f5da8c574f87e93 /usr/local/bin/op /usr/local/bin/op

# uv (Python package manager). Kept in the image so the agent can create project
# venvs at runtime; also used below to install the Hermes plugin requirements.
COPY --from=ghcr.io/astral-sh/uv:0.13.9@sha256:d3b601f0c7b118bc1753febf7c41cc80981df678445e0254284eecf84db79a7d /uv /uvx /usr/local/bin/

# Extra Python packages for Hermes plugins, installed into the (sealed) hermes
# venv at build time so they survive container recreation.
COPY requirements.txt /tmp/requirements.txt
RUN uv pip install --python /opt/hermes/.venv/bin/python --no-cache -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Go toolchain (lespelos/wep backend/go.mod requires go >= 1.26.3). Copied from the
# official golang image so Renovate keeps tag + digest current.
COPY --from=golang:1.27.4@sha256:205c7636d74e0ffbe3d007162df7d74f859f5a8c8322dfb9f907977686c126cf /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version && uv --version

# jq and shellcheck from Debian (unpinned, like jq: they follow the base image
# rather than Renovate).
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq shellcheck \
    && rm -rf /var/lib/apt/lists/* \
    && jq --version \
    && shellcheck --version

# GitHub CLI: pinned release tarball verified against the release checksums file
# (the Debian package is far older). TARGETARCH is provided by BuildKit.
# renovate: datasource=github-releases depName=cli/cli
ARG GH_VERSION=2.105.0
ARG TARGETARCH
RUN set -eux; \
    mkdir /tmp/gh; cd /tmp/gh; \
    curl -fsSLO "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz"; \
    curl -fsSLO "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_checksums.txt"; \
    sha256sum --check --ignore-missing "gh_${GH_VERSION}_checksums.txt"; \
    tar -xzf "gh_${GH_VERSION}_linux_${TARGETARCH}.tar.gz"; \
    install -m 0755 "gh_${GH_VERSION}_linux_${TARGETARCH}/bin/gh" /usr/local/bin/gh; \
    cd /; rm -r /tmp/gh; \
    gh --version

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
