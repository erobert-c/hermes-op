# hermes-op

[Nous Hermes Agent](https://github.com/NousResearch/hermes-agent) image with the
[1Password CLI](https://developer.1password.com/docs/cli) (`op`) built in.

    docker pull ghcr.io/erobert-c/hermes-op:latest

Base image and `op` versions are pinned in the `Dockerfile` and updated by Renovate
(patch/minor/digest updates automerge once the build passes; majors need review).

## Maintenance setup (one-time)

1. Create a fine-grained PAT scoped to this repo with **Contents**, **Pull requests**,
   **Workflows** (read/write), and **Metadata** (read).
2. Save it as the repo secret `RENOVATE_TOKEN`.
3. Under Settings → Branches, require the `build` status check on `main` so automerge
   waits for CI; enable "Allow auto-merge" in repo settings.

Renovate runs daily via `.github/workflows/renovate.yml`.
