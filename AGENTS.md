# Agent Instructions

## ⚠️ Pending TODOs

- **homura only**: `services.dbus.implementation = "dbus"` is pinned in `hosts/homura/default.nix` to defer the dbus → dbus-broker transition until a reboot. Once homura has been rebooted, remove that line and redeploy. *(Remove this note when done.)*

## Tailscale IPs

| Host | IP |
|------|----|
| sayaka | 100.77.12.60 |
| homura | 100.116.202.116 |
| starscream | 100.102.158.29 |
| ubuntu-2gb-ash-1 | 100.102.161.7 |

These are private tailnet addresses and are safe to use in config files and commit to the repo.

## Generating secrets

When asked to generate a new agenix secret, run:

```bash
cd <absolute-path-to-repo>/secrets && echo "<CONTENT>" | agenix -e <secret-name>.age
```

agenix must be run from the `secrets/` directory of this repo so it can find `secrets.nix`. Always resolve the absolute path to the repo root first (e.g. via `git rev-parse --show-toplevel`) rather than assuming a hardcoded path.

### Secret values must never appear in agent context

The agent's context window is not secure. If a secret value is visible in any tool output, response, or read file, it is compromised and must be regenerated.

Secret values must be generated inline in the shell command itself (e.g. `$(openssl rand -hex 32)`), or sourced by `cat`-ing a file that the agent has **not** read. Never read a secret file, never echo a known value, never include a plaintext secret in a response.
