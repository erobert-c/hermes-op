FROM nousresearch/hermes-agent:v0.22.2@sha256:36099926da316742423544e055d4734777105ffe6341873af5459b957d0c2919

LABEL org.opencontainers.image.source="https://github.com/erobert-c/hermes-op" \
      org.opencontainers.image.description="Nous Hermes Agent with the 1Password CLI (op)"

COPY --from=1password/op:2.41.0@sha256:c218de9c39ac1a65ca1e98b634aa132bee1ff94d762d01d5cdfeebbc3413c697 /usr/local/bin/op /usr/local/bin/op
