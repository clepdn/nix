# Agent Instructions

## Generating secrets

When asked to generate a new agenix secret, do not write plaintext to disk or include secret values in your responses. Instead, write a temporary script to `$XDG_RUNTIME_DIR` (in-memory tmpfs), run it, then delete it.

The script should:
1. `cd` to `/home/callie/code/nix/secrets`
2. Generate any random values (e.g. `openssl rand -hex 24`)
3. Write the plaintext to another tmpfile in `$XDG_RUNTIME_DIR`
4. Set `EDITOR` to a script that copies that tmpfile into agenix's plaintext buffer
5. Call `agenix -e <secret-name>.age`
6. Clean up all tmpfiles on exit via `trap`

agenix must be run from `/home/callie/code/nix/secrets/` so it can find `secrets.nix`.
