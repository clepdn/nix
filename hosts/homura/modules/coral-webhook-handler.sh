#!/usr/bin/env bash
set -euo pipefail
read -r _method path _version
while IFS= read -r line && [ "${line%$'\r'}" != "" ]; do
  :
done

token="${path#*\?token=}"
token="${token%%&*}"
token="${token#*=}"

expected_token="$(cat "$WEBHOOK_TOKEN_FILE")"

if [ "$token" != "$expected_token" ] || [ -z "$token" ]; then
  printf "HTTP/1.1 403 Forbidden\r\nContent-Type: text/plain\r\n\r\ninvalid token\n"
  exit 1
fi

printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nstarting rebuild...\n"
exec nixos-container update coral --flake /var/lib/nixos-containers/coral/home/coral/nix#reef 2>&1
