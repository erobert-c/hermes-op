# Claude CLI + git tooling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the Claude Code CLI (pinned, Renovate-tracked, login persisted in the Hermes volume) plus `git`/`openssh-client` in the hermes-op image.

**Architecture:** Extend the existing Dockerfile. Claude installs through npm with the version in an `ARG` that Renovate updates. `CLAUDE_CONFIG_DIR` points into `/opt/data` (the user's mounted volume). No sync logic is added to the image.

**Tech Stack:** Docker, npm, Renovate.

**Spec:** `docs/superpowers/specs/2026-11-21-claude-cli-and-vault-sync-design.md`

## Global Constraints

- `ENV CLAUDE_CONFIG_DIR=/opt/data/claude`; no change to the user's compose file.
- Claude version pinned in `ARG CLAUDE_CODE_VERSION`, preceded by `# renovate: datasource=npm depName=@anthropic-ai/claude-code`.
- No sync script, cron or loop in the image. `git`, `openssh-client` and `op` must be present.
- If the base image lacks Node, copy it from a pinned `node` image (tag + digest).
- Existing patch/minor automerge rule in `renovate.json` must cover the new dependency.

## Review Focus

- Container runs as a non-root user: `/opt/data/claude` must be writable by it.
- `~/hermes` on the host starts without a `claude` dir: `claude` must create it on first run.
- Container recreated from a new image: login still present (config lives in the volume).
- Renovate must actually detect the ARG (check with `renovate-config-validator` and a dry run if possible).

---

### Task 1: Dockerfile and Renovate config

**Files:**
- Modify: `Dockerfile`
- Modify: `renovate.json`

**Interfaces:**
- Produces: image with `claude`, `git`, `ssh`, `op` on PATH and `CLAUDE_CONFIG_DIR=/opt/data/claude`.

- [ ] **Step 1: Inspect the base image** to settle the open items:
  `docker run --rm --entrypoint sh nousresearch/hermes-agent:v0.23.3 -c 'id; which node npm git ssh; echo $HOME; ls -ld /opt/data'`
  Record which of node/git/ssh are missing and which user runs the container.

- [ ] **Step 2: Write the failing check.** Build the current Dockerfile and run
  `docker run --rm --entrypoint sh <image> -c 'claude --version && git --version && ssh -V && op --version'`
  Expected: FAIL (`claude: not found`).

- [ ] **Step 3: Edit `Dockerfile`:** add the `ARG CLAUDE_CODE_VERSION=<current latest from npm view @anthropic-ai/claude-code version>` with the Renovate comment above it, install `git` and `openssh-client` (and Node via pinned `node` image if Step 1 showed it is missing), `npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`, and `ENV CLAUDE_CONFIG_DIR=/opt/data/claude`. Keep the existing `op` and `uv` lines unchanged. Update the image description label.

- [ ] **Step 4: Edit `renovate.json`:** add `"customManagers:dockerfileVersions"` to `extends`.

- [ ] **Step 5: Verify.**
  - Rebuild and rerun the Step 2 command. Expected: all four versions print.
  - `docker run --rm -v $(mktemp -d):/opt/data --entrypoint sh <image> -c 'claude --version; mkdir -p $CLAUDE_CONFIG_DIR && touch $CLAUDE_CONFIG_DIR/x && echo writable'` as the image's default user. Expected: `writable` (if not, fix ownership per Step 1 findings, e.g. via `chown` in the Dockerfile or documenting it).
  - `npx --yes --package renovate renovate-config-validator renovate.json`. Expected: valid.

- [ ] **Step 6: Commit**

```bash
git add Dockerfile renovate.json
git commit -m "feat: add Claude Code CLI, git and ssh to image"
```

### Task 2: README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Document** (keep it short): what the image now contains; that login persists in `~/hermes/claude` via `CLAUDE_CONFIG_DIR`; the one-time `docker exec -it hermes claude` login; and that the agent syncs the vault itself from a private GitHub repo using a read/write deploy key stored in 1Password and fetched with `op` (no sync logic in the image).

- [ ] **Step 2: Verify** the README matches the Dockerfile (names, paths). Expected: no mismatch.

- [ ] **Step 3: Commit**

```bash
git add README.md docs
git commit -m "docs: document Claude CLI login and vault sync"
```
