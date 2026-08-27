# Codex Remote Control on Homura

Homura runs Codex Remote Control as the Nix-managed `codex-remote-control.service` unit under the non-root `callie` account. The oneshot unit invokes `codex remote-control start`, which starts Codex's managed app-server daemon with remote control enabled, then remains active. `systemctl stop` invokes `codex remote-control stop`. The daemon inherits a Nix-pinned runtime path that includes `ps`, which its PID manager requires.

`CODEX_HOME=/home/callie/.codex` is mutable state outside the Nix store. Homura's `/home` filesystem is persistent. Keep this directory private and preserve it across generations.

## First-time authentication

Run these commands as the service user. The generated helpers use the selected Nix package, `HOME`, `CODEX_HOME`, and file-backed credentials store used by the service.

```sh
sudo -u callie -H codex-remote-login --device-auth
sudo -u callie -H codex-remote-login-status
```

The unit is skipped until `/home/callie/.codex/auth.json` exists. Start it after authentication:

```sh
sudo systemctl start codex-remote-control.service
```

Validate the selected binary's experimental interface before pairing:

```sh
sudo -u callie -H codex-remote-check
```

## Pairing

Generate a short-lived code only from an operator terminal. It is printed, not persisted:

```sh
sudo -u callie -H codex-remote-pair
```

Pair from the ChatGPT/Codex client using the same account/workspace. No inbound firewall port is required.

## Operations and diagnostics

```sh
sudo systemctl status codex-remote-control.service
sudo journalctl -u codex-remote-control.service -b
sudo journalctl -fu codex-remote-control.service
sudo systemctl restart codex-remote-control.service
sudo -u callie -H codex-remote-login-status
sudo -u callie -H codex-remote-doctor
```

A clean `systemctl stop` invokes the managed daemon stop command and leaves the oneshot unit inactive. Authentication, pairing, sessions, SQLite state, configuration, and plugins remain under `CODEX_HOME`.

## Migration from an existing daemon

There must be one owner of Codex's app-server control socket.

1. Inspect the installed binary and process tree:

   ```sh
   command -v codex
   codex --version
   ps -fu callie | grep -E 'codex.*(remote-control|app-server|proxy)' | grep -v grep
   ```

2. Stop any existing Codex-managed lifecycle with the binary that created it:

   ```sh
   codex remote-control stop
   codex app-server daemon stop
   ```

3. Disable old hand-written or Home Manager units that also own the app-server daemon.
4. Disconnect active Codex Desktop SSH remote sessions if they spawn a separate app server.
5. Confirm no old process owns the control socket before starting the Nix unit.
6. Do not delete `auth.json`, `state_*.sqlite`, sessions, configuration, or pairing state.
7. Start the Nix unit and inspect the process tree and journal.

Do not delete sockets or SQLite state to hide an ownership conflict. Diagnose and stop the process that owns them.

## Updates and rollback

Nix is the only Codex updater. Review Remote Control changes, then test and switch the new generation using the repository's normal workflow:

```sh
nix flake lock --update-input nixpkgs
nixos-rebuild test --flake .#homura
nixos-rebuild switch --flake .#homura
```

The package path is embedded in the service wrapper and listed as a restart trigger, so a package change restarts the unit onto the new store path. Verify the running version after switching:

```sh
sudo -u callie -H /run/current-system/sw/bin/codex --version
sudo systemctl status codex-remote-control.service
```

If the new generation breaks pairing or connectivity, use the normal NixOS rollback:

```sh
sudo nixos-rebuild switch --rollback
```

Never run `codex update` or the standalone installer on Homura.

## Security boundary

The service account's paired clients can exercise that account's filesystem and command privileges. Keep repository access, Git credentials, SSH credentials, and account groups within the intended trust boundary. Do not run the service as root or expose an app-server TCP/WebSocket listener.
