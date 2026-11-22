# hermes-op

[Nous Hermes Agent](https://github.com/NousResearch/hermes-agent) image with the
[1Password CLI](https://developer.1password.com/docs/cli) (`op`) and the
[Claude Code](https://docs.claude.com/en/docs/claude-code) CLI (`claude`) built in, plus
dev tools: `gh`, `jq`, `uv` and the Go toolchain (`go`). `git` and `openssh-client` come
from the base image.

    docker pull ghcr.io/erobert-c/hermes-op:latest

Base image, `op`, `claude`, `gh`, `uv` and Go versions are pinned in the `Dockerfile` and updated by Renovate
(patch/minor/digest updates automerge once the build passes; majors need review).

## Claude Code login

`CLAUDE_CONFIG_DIR` is set to `/opt/data/claude`, inside the Hermes data volume, so the
login survives restarts and image upgrades. Log in once, as the `hermes` user (without
`-u hermes` the credentials would be created as root and the agent could not read them):

    docker exec -it -u hermes hermes claude

## Vault sync

The image contains no sync logic. The agent syncs a private GitHub repo itself, using
a read/write deploy key stored in 1Password and fetched with `op`, into the data volume
(e.g. `/opt/data/vault`).

## Maintenance setup (one-time)

1. Create a fine-grained PAT scoped to this repo with **Contents**, **Pull requests**,
   **Workflows** (read/write), and **Metadata** (read).
2. Save it as the repo secret `RENOVATE_TOKEN`.
3. Under Settings → Branches, require the `build` status check on `main` so automerge
   waits for CI; enable "Allow auto-merge" in repo settings.

Renovate runs daily via `.github/workflows/renovate.yml`.
