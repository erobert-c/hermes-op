# Claude CLI + git vault sync for hermes-op

## Intent
Add the Claude Code CLI to the image, logged in once with a Claude subscription,
without re-authenticating after container restarts. Sync a personal Obsidian
vault (people, gift ideas) between the container and the user's phone without
Google Drive.

## Goals
- `claude` available in the image; login survives restarts and image upgrades.
- Image provides git/ssh/op so the agent can sync the vault with a private GitHub repo.
- No new compose volumes: everything lives in the existing Hermes home volume.
- Versions pinned so Renovate can track them.

## Non-goals
- Live sync (explicitly not needed), Obsidian LiveSync/CouchDB.
- Any sync automation inside the image (the agent handles sync on its own).
- API-key or `setup-token` auth.

## Constraints
- Compose stack with only the Hermes home mapped as a volume.
- 1Password CLI (`op`) already present; secrets should come through it.
- Vault contains personal data about people, so the repo must be private.

## Approaches
- Auth: (A) `CLAUDE_CONFIG_DIR` inside the Hermes home volume [chosen]; (B) separate
  volume; (C) `setup-token` via `op`. A needs no new mounts.
- Sync: (1) private GitHub repo with deploy key [chosen]; (2) self-hosted bare repo;
  (3) LiveSync. 1 is the simplest and the user picked it.

## Design
1. Dockerfile: install the Claude Code CLI at a pinned version; ensure `git` and
   `openssh-client` exist. Set `ENV CLAUDE_CONFIG_DIR=/opt/data/claude`
   (Hermes home is `/opt/data`, mounted from `~/hermes` in the user's compose file,
   so no compose change is needed).
2. First login: one-time `docker exec -it <container> claude`; credentials persist in the volume.
3. Vault sync is done by the Hermes agent itself, not by the image. The image
   ships no sync script, cron or loop. It only provides the tools: `git`,
   `openssh-client` and `op`. The agent clones and syncs the private GitHub repo
   into the Hermes home volume, using a deploy key stored in 1Password and
   fetched with `op` (never baked into the image).
4. Renovate: install via npm with the version in a Dockerfile `ARG CLAUDE_CODE_VERSION`
   preceded by a `# renovate: datasource=npm depName=@anthropic-ai/claude-code` comment;
   add `customManagers:dockerfileVersions` to `extends` in renovate.json. The existing
   patch/minor automerge rule applies. If the base image lacks Node, copy it in from a
   pinned `node` image.
5. README updated with the compose snippet (env vars, the one-time login) and a
   note on the vault repo and deploy key setup for the agent.

## Left to the builder
Which user the container runs as (file ownership under /opt/data), and which of
git/openssh-client are already in the base image.
