FROM nousresearch/hermes-agent:v0.22.7@sha256:e6d81ae52ebf6a43efa529701405509f20054ba818f179ddd748bed4f8af584c

LABEL org.opencontainers.image.source="https://github.com/erobert-c/hermes-op" \
      org.opencontainers.image.description="Nous Hermes Agent with the 1Password CLI (op)"

COPY --from=1password/op:2.42.0@sha256:b0d7eebcb09bdc9d5862af91533e1851c968d4f969270c906f5da8c574f87e93 /usr/local/bin/op /usr/local/bin/op

# Extra Python packages for Hermes plugins, installed into the (sealed) hermes
# venv at build time so they survive container recreation.
COPY requirements.txt /tmp/requirements.txt
RUN --mount=from=ghcr.io/astral-sh/uv:0.13.7@sha256:96f40d3904aad8d0bd010539001d36c8e2188b981e1334471a90c4a1d93bb490,source=/uv,target=/usr/local/bin/uv \
    uv pip install --python /opt/hermes/.venv/bin/python --no-cache -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt
