# Agent Instructions

Most queries will be related to the NixOS config here. If the user wants you to setup something, or configure something, it will be done here.

## Debugging
When debugging we can ssh into other machines to get their journal output or run benign commands for more information.
Only use ssh if we actually need it. If the machine we are debugging is the current one (check via `hostname`), then just run the commands normally.
`journalctl` and `systemctl status` can and should be run without sudo.

## Shell
Your shell is not a real tty. `sudo` will fail. you do not have a path to root. You will be able to accomplish every task I set out for you without sudo. Be creative.
The user is to set off rebuilds.

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

agenix secrets are benign to generate on autonomously. Its best not to defer to the user for creating secrets unless absolutely necessary.

### Secret values must never appear in agent context

The agent's context window is not secure. If a secret value is visible in any tool output, response, or read file, it is compromised and must be regenerated.

Secret values must be generated inline in the shell command itself (e.g. `$(openssl rand -hex 32)`), or sourced by `cat`-ing a file that the agent has **not** read. Never read a secret file, never echo a known value, never include a plaintext secret in a response.

agenix enables us to deal with secrets without actually reading the values.
