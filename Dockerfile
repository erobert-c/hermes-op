FROM nousresearch/hermes-agent:v0.23.2@sha256:d6746a084e9341baada483e3d6210444d3c1aeb7c130f0915150065fb2851459

LABEL org.opencontainers.image.source="https://github.com/erobert-c/hermes-op" \
      org.opencontainers.image.description="Nous Hermes Agent with the 1Password CLI (op)"

COPY --from=1password/op:2.42.0@sha256:b0d7eebcb09bdc9d5862af91533e1851c968d4f969270c906f5da8c574f87e93 /usr/local/bin/op /usr/local/bin/op

# Extra Python packages for Hermes plugins, installed into the (sealed) hermes
# venv at build time so they survive container recreation.
COPY requirements.txt /tmp/requirements.txt
RUN --mount=from=ghcr.io/astral-sh/uv:0.13.8@sha256:5cc1805e2426484abca4ad46ea783bab281fdb225fd82d8ce6d66a81254bac85,source=/uv,target=/usr/local/bin/uv \
    uv pip install --python /opt/hermes/.venv/bin/python --no-cache -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt
