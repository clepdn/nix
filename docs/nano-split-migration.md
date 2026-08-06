# Nano control-plane / executor split — migration runbook

Splits nano into two services across two machines:

- **Control plane** (`services.nano`, on **homura**): the brain — LLM loop,
  session, memory, compaction, Discord. Holds all continuity. Runs **no tools**,
  and is sandboxed hard (dedicated system user, no wheel/sudo, `ProtectSystem`
  strict, state confined to `StateDirectory=/var/lib/nano`).
- **Executor** (`services.nano-executor`, on **reef**): the hands — shell,
  file, image, computer tools, sandboxed in the nspawn container. Keeps the
  permissive tool-runner shape (login user, sudo). Replaceable.

They talk over an authenticated REST boundary on the private veth
(homura `10.233.1.1` ↔ reef `10.233.1.2`). If reef dies, the control plane
stays up: nano keeps her session/memory and is still reachable over Discord,
she just loses tool execution until reef reconnects.

## Wiring

- reef imports `nano.nixosModules.nano-executor`, binds `10.233.1.2:4221`.
- homura imports `nano.nixosModules.default` (control plane) + keeps llm-bridge.
- homura's agent `client = "http://10.233.1.2:4221"`, authenticated with the
  shared token (`executorTokenFile`).

## Prerequisites (do BEFORE the first switch)

1. **Update the nano flake input** to a revision that has the executor module
   and the nano rename:
   ```
   nix flake update nano
   ```
   (This split depends on the harness PR "authenticated executor +
   nano-executor nixos module" + the niri/coral -> nano rename being merged.)

2. **Create the shared token secret**, decryptable on both hosts:
   ```
   head -c 32 /dev/urandom | base64 > /tmp/tok
   RULES=./secrets/secrets.nix agenix -e secrets/nano-executor-token.age < /tmp/tok
   shred -u /tmp/tok
   ```
   (Recipients `homura_pq` + `reef_pq` are already declared in secrets.nix.)

3. **Migrate nano's durable state** from the reef container to `/var/lib/nano`
   on homura — this is her brain, it must live with the control plane:
   ```
   memories/   soul.md   niri.db   metrics.db   control/
   ```
   They now sit in `/home/nano` inside the container (see below). Copy with
   rsync while the reef nano-executor service is stopped, preserving perms.
   The state dir is `0700` and owned by the `nano` service user. **Not done
   yet** — `/var/lib/nano` does not exist on homura.

## Cutover order

1. Deploy **reef** first (executor comes up, tokenless clients get 401):
   `nixos-container update coral` (or in-container rebuild). NOTE: the nspawn
   container is still named `coral` at the systemd level — only the software
   inside is renamed. Renaming the container is a separate migration.
2. Deploy **homura** (control plane connects to the reef executor).
3. Verify: `journalctl -u nano -f` on homura shows the executor handshake
   succeed; nano answers a Discord DM and can run a `shell` tool.

## Failure mode (the point of all this)

- reef down → control plane stays up, session + memory intact, nano still
  answers DMs; tool calls return an error result until reef returns. No restart,
  no amnesia. The HttpToolClient degrades gracefully by design.
- homura down → nano is fully offline (the brain is there). This is expected;
  homura is the durable host.

## Notes / open items

- The HRT shot-reminder timer still lives on reef and now targets the homura
  control-plane worker webhook (`http://10.233.1.1:4220/trigger/webhook`).
  Confirm the worker's webhook port after the control plane is live; consider
  moving the timer to homura alongside the loop.
- Executor `capabilities` are client tool names: `shell`, `read_file`,
  `edit_file`, `image_tool`, `computer`, `read_bytes`. Anything else (discord,
  memory, subagents, web search) runs in the control plane.
- `computer` and `read_bytes` exist so the split keeps parity: xdotool/`import`
  drive reef's Xvfb `:99` (the control plane only supplies `display`), and
  `discord_upload` pulls its bytes off the executor instead of homura's disk.
  The 1 MB client image ceiling is raised via `imageMaxBytes` — a full-screen
  screenshot blows straight through the default.
- `/home/coral` became `/home/nano` (2026-08-06). The rename had orphaned it
  under uid 1001 with no passwd entry; 84k files, 14 GB, moved within the same
  filesystem, chowned to `nano`, absolute symlinks repointed, and
  `.harness.toml` / `bin/rebuild` / `scripts/*.sh` rewritten. Journals,
  memories, `soul.md`, patches and git checkouts still say `/home/coral`
  because that is what it was — history, not config. Her `nix profile` links
  were already dangling (store paths GC'd) before the move.
- The nspawn container name (`coral`) and the pre-existing `coral*.age` secrets
  (real API keys) are intentionally NOT renamed here — they need re-encryption /
  container recreation and belong in a follow-up.
