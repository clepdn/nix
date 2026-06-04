# Mail setup guide

First-time bring-up for the `myNixOS.mail` module on homura, with sayaka
fronting public SMTP and comail.at handling outbound relay.

Topology:

```
inbound:   internet ──► sayaka:25  ──(PROXY)──► homura:25  ──► dovecot LMTP
submission: tenant   ──► sayaka:587 ──(PROXY)──► homura:587 ──► comail
outbound:  homura postfix ──(SASL 587)──► smtp.atmos.email ──► world
IMAP:      tenant ──tailnet──► homura:993
```

This guide assumes the nix code is already merged. Steps are ordered so each
phase is independently testable.

---

## 0. Pre-flight: what you need before touching anything

- A comail.at account with `on-her.computer` (or whichever primary domain)
  enrolled. You should have an API key starting `atmos_…`.
- Access to Cloudflare DNS for the primary domain.
- The `agenix` dev shell available: `nix develop` in the repo root.
- sayaka's public IPv4 address handy.
- A bcrypt hash for each initial tenant (we'll generate these below).

---

## 1. DNS

Add these records in Cloudflare for `on-her.computer`. They can all go in
before any deploy; nothing here is dangerous.

| Type  | Name              | Value                                              |
|-------|-------------------|----------------------------------------------------|
| A     | `mail`            | `<sayaka public IPv4>`                             |
| MX    | `@`               | `10  mail.on-her.computer.`                        |
| TXT   | `@`               | `v=spf1 mx include:atmos.email -all`               |
| TXT   | `_dmarc`          | `v=DMARC1; p=quarantine; rua=mailto:postmaster@on-her.computer` |
| CNAME | `<sel>._domainkey`| value from comail enrollment (DKIM)                |

> **DKIM:** comail's enrollment flow shows you the exact CNAME records to
> add. Usually two selectors — one your-domain-keyed, one
> `atmos.email`-keyed. Add both verbatim.

Don't proxy any of these through Cloudflare (orange cloud off). Mail
doesn't go over HTTP.

### PTR / rDNS

Set sayaka's public IPv4 PTR to `mail.on-her.computer.` at your VPS
provider. This is required for some receiving MTAs (notably Yahoo, some
self-hosted setups) even when comail handles the actual sending. Not
strictly required to start.

Verify all of this with:

```bash
dig +short MX on-her.computer
dig +short A mail.on-her.computer
dig +short TXT on-her.computer
dig +short -x <sayaka public IP>     # PTR
```

---

## 2. Generate the agenix secrets

All secret values must be generated inline or piped from files the agent
never sees. Run these in your own shell.

### 2a. Comail SASL credentials

```bash
cd "$(git rev-parse --show-toplevel)/secrets"

# Replace atmos_XXXX with your real API key. Type it directly into the shell.
# The file is a single line in postfix sasl_passwd format.
printf '[smtp.atmos.email]:587 on-her.computer:atmos_XXXXXXXXXXXXXXXXXXXX\n' \
  | agenix -e comail-sasl.age
```

### 2b. Per-tenant bcrypt password hashes

For each tenant, generate a `BLF-CRYPT` hash with `doveadm pw`. Don't paste
the plaintext password anywhere except your own terminal.

```bash
cd "$(git rev-parse --show-toplevel)/secrets"

# Type the password when prompted (twice). Output looks like:
#   {BLF-CRYPT}$2y$05$.....
# We strip the trailing newline and pipe into agenix.
nix shell nixpkgs#dovecot -c doveadm pw -s BLF-CRYPT \
  | tr -d '\n' \
  | agenix -e mail-passwd-callie.age
```

Repeat for each additional tenant (`mail-passwd-bob.age`, etc.). Don't
forget to register each new secret in `secrets/secrets.nix` and add a
matching `age.secrets.…` block and `myNixOS.mail.users.…` entry in
`hosts/homura/modules/mail.nix`.

---

## 3. First deploy

Deploy in this order. Each step is independently testable.

### 3a. Homura first (issues the cert, starts postfix + dovecot)

```bash
# From your laptop, or however you normally rebuild homura.
./rebuild.fish homura      # or: nixos-rebuild switch --flake .#homura --target-host …
```

Watch for these on homura after activation:

```bash
# Cert was issued
sudo ls /var/lib/acme/mail.on-her.computer/
# fullchain.pem  full.pem  key.pem  cert.pem  ...

# Both services up
systemctl status postfix dovecot2 postfix-sasl-passwd dovecot-passwd

# The two map files exist and are readable
sudo postconf -n | grep -E '(virtual_alias_maps|sasl_password_maps|sender_login)'
ls -la /etc/postfix/{virtual,virtual.db,generic,generic.db,sender_login,sender_login.db}
ls -la /var/lib/postfix/conf/sasl_passwd{,.db}

# dovecot's virtual-user passwd file populated correctly
sudo cat /run/dovecot2/passwd
# callie@on-her.computer:{BLF-CRYPT}$2y$05$...:5000:5000::/var/vmail/on-her.computer/callie::
```

If `postfix-sasl-passwd` failed: the agenix secret probably isn't readable.
Check `journalctl -u postfix-sasl-passwd`.

If `dovecot-passwd` failed: a tenant's password-hash secret is missing or
malformed. Check `journalctl -u dovecot-passwd`.

If postfix won't start: `journalctl -u postfix -e` and `postfix check`.

### 3b. Local smoke tests (still on homura, before opening to the world)

```bash
# IMAP login from inside homura
openssl s_client -connect 127.0.0.1:993 -crlf -quiet <<'EOF'
a1 LOGIN callie@on-her.computer PASSWORD-HERE
a2 LIST "" "*"
a3 LOGOUT
EOF

# Local submission (this won't go anywhere yet, but proves the pipeline
# accepts auth). swaks is in nixpkgs.
nix shell nixpkgs#swaks -c \
  swaks --server 127.0.0.1 --port 587 --tls \
        --auth-user callie@on-her.computer --auth-password 'PASSWORD-HERE' \
        --from callie@on-her.computer --to YOUR_OTHER_ADDRESS@example.com \
        --header 'Subject: smoke test'
```

If the swaks send returns `250 ok` and a few seconds later you have mail at
the recipient — outbound through comail is working.

If you see `530 sender not owned by user`: `smtpd_sender_login_maps` is
rejecting the From. Verify the From address exactly matches the auth user
or one of its aliases.

If you see `535 authentication failed`: dovecot couldn't verify the
password. Check that `/run/dovecot2/passwd` has a `{BLF-CRYPT}` prefix on
the hash, or omit the prefix consistently and tweak the `scheme=` in the
passdb args.

### 3c. Sayaka (opens public ports)

```bash
./rebuild.fish sayaka
```

After activation:

```bash
# From sayaka
ss -tlnp | grep -E ':(25|587)\b'
# Should show nginx listening on both.
```

### 3d. End-to-end inbound test

From any external box (e.g. your laptop on cellular, or any VPS):

```bash
# This connects to sayaka:25 → proxied to homura:25 → delivered to dovecot
swaks --server mail.on-her.computer --port 25 \
      --from test@gmail.com --to callie@on-her.computer \
      --header 'Subject: inbound test'
```

Then read it via IMAP from homura's tailnet IP:

```bash
# From a tailnet-connected machine
openssl s_client -connect homura:993 -crlf -quiet
# a1 LOGIN callie@on-her.computer 'password'
# a2 SELECT INBOX
# a3 FETCH 1 BODY[]
```

Then send yourself a real test from Gmail to `callie@on-her.computer` and
verify it lands.

### 3e. End-to-end outbound test from a real MUA

Configure Thunderbird/Apple Mail/whatever with:

| Setting               | Value                       |
|-----------------------|-----------------------------|
| IMAP host             | `homura` (tailnet) or `homura.<tailnet-domain>` |
| IMAP port             | `993`                       |
| IMAP security         | SSL/TLS                     |
| IMAP username         | `callie@on-her.computer`    |
| IMAP password         | the password you generated  |
| SMTP host             | `mail.on-her.computer`      |
| SMTP port             | `587`                       |
| SMTP security         | STARTTLS                    |
| SMTP auth             | normal password             |
| SMTP username         | `callie@on-her.computer`    |
| SMTP password         | same as IMAP                |

Send a test to your Gmail; reply from Gmail; verify both directions work.
Check the headers on what Gmail received:

```
Authentication-Results: mx.google.com;
       dkim=pass header.i=@on-her.computer
       dkim=pass header.i=@atmos.email
       spf=pass smtp.mailfrom=on-her.computer
       dmarc=pass
```

Two `dkim=pass` lines is the chatmail dual-signing working. If you only
see one, the per-domain DKIM CNAME from step 1 hasn't propagated or
matches the wrong selector.

---

## 4. Adding a new tenant

After the first deploy, adding `bob@on-her.computer`:

1. Generate the secret:
   ```bash
   cd "$(git rev-parse --show-toplevel)/secrets"
   nix shell nixpkgs#dovecot -c doveadm pw -s BLF-CRYPT \
     | tr -d '\n' \
     | agenix -e mail-passwd-bob.age
   ```

2. Add the entry in `secrets/secrets.nix`:
   ```nix
   "mail-passwd-bob.age".publicKeys = DEPRECATED_sshKeys;
   ```

3. Add to `hosts/homura/modules/mail.nix`:
   ```nix
   age.secrets."mail-passwd-bob" = {
     file = "${self}/secrets/mail-passwd-bob.age";
     owner = "root"; group = "root"; mode = "400";
   };
   # …
   myNixOS.mail.users.bob = {
     passwordHashFile = config.age.secrets."mail-passwd-bob".path;
     aliases = [ "robert@on-her.computer" ];   # optional
   };
   ```

4. Rebuild homura. The `dovecot-passwd` oneshot regenerates the passwd
   file at the start of the activation and dovecot picks it up.

No restart of postfix is strictly required for new tenants (virtual map is
re-`postmap`ped by the activation script). But if a tenant authenticates
and gets `535`, `systemctl restart dovecot2` and try again.

---

## 5. Adding a second domain

Comail allows 2 enrolled domains per DID during the alpha; beyond that you
need a second DID and a different relay credential.

For a second domain on the **same comail account**:

1. Enroll the new domain in comail's dashboard. Add its DNS records
   (DKIM CNAMEs, SPF — the existing MX can stay if both domains receive
   on the same MX).

2. Add to `hosts/homura/modules/mail.nix`:
   ```nix
   myNixOS.mail.extraDomains = [ "other.example" ];
   ```

3. Add tenants on the new domain:
   ```nix
   myNixOS.mail.users.alice = {
     domain = "other.example";
     passwordHashFile = config.age.secrets."mail-passwd-alice".path;
   };
   ```

For a second domain on a **separate comail account** (different SASL
creds): the current module assumes one shared relay. You'd need to extend
it with `sender_dependent_relayhost_maps` and per-sender SASL entries.
File a future-self issue.

---

## 6. Rotating a tenant password

```bash
cd "$(git rev-parse --show-toplevel)/secrets"
nix shell nixpkgs#dovecot -c doveadm pw -s BLF-CRYPT \
  | tr -d '\n' \
  | agenix -e mail-passwd-callie.age
```

Then rebuild homura. The `dovecot-passwd` oneshot rewrites
`/run/dovecot2/passwd`. Dovecot rereads passwd-file on every auth so no
restart is needed — but if a session is mid-auth during the swap, retry.

---

## 7. Troubleshooting

| Symptom | Likely cause | Where to look |
|---------|--------------|---------------|
| `530 5.7.1 Sender address rejected: not owned by user` | From: doesn't match auth user or any alias | `smtpd_sender_login_maps`, `/etc/postfix/sender_login` |
| `535 authentication failed` | dovecot can't verify, or passwd-file scheme mismatch | `journalctl -u dovecot2`, check `/run/dovecot2/passwd` |
| Inbound mail rejected `550 Relay access denied` | virtual_alias_domains missing the recipient domain | `postconf virtual_alias_domains`, check `myNixOS.mail.extraDomains` |
| `Connection refused` on :25 from outside | sayaka firewall closed, or homura :25 refusing | `ss -tlnp` on both; check `networking.firewall.allowedTCPPorts` |
| `proxy_protocol header read timeout` in postfix logs | sayaka isn't sending PROXY proto, or postfix isn't expecting it | both sides must agree; check `proxy_protocol on;` in nginx and `smtpd_upstream_proxy_protocol = haproxy` in postfix |
| Comail rejects send with `domain not enrolled` | `MAIL FROM` domain isn't enrolled with comail | check `smtp_generic_maps` rewriting; only enrolled domains can send |
| Gmail flags as spam | DKIM/SPF/DMARC misalignment | examine `Authentication-Results` on a sent message; both dkim signatures must pass |
| Cert renewal didn't reload postfix | `reloadServices` not set on the cert | already declared in the module; verify with `systemctl cat acme-mail.on-her.computer.service` |

### Useful diagnostic commands

```bash
# What postfix actually thinks its config is
sudo postconf -n                 # non-default settings
sudo postconf -M                 # master.cf
sudo postqueue -p                # mail queue
sudo postqueue -f                # flush deferred mail

# What dovecot thinks
sudo doveconf -n
sudo doveadm log find
sudo doveadm user 'callie@on-her.computer'   # verify userdb lookup

# Tail logs
journalctl -u postfix -f
journalctl -u dovecot2 -f
```

---

## 8. Things to revisit later

- **rspamd / spam filtering.** Not in the module yet. Inbound mail goes
  straight to maildirs untouched. For now, rely on MUA-side filters or
  comail's outbound side. If volume grows, add rspamd as a content_filter
  or via `smtpd_milters`.
- **Sieve filtering.** Easy add: enable `dovecot2.sieve.enable` and let
  users `~/.dovecot.sieve` themselves, or define `services.dovecot2.sieve.scripts`
  module-side.
- **Backup / maildir snapshots.** `/var/vmail` is the source of truth. It
  should be on the btrfs hdd (already is, by default placement of
  `/var`). Add it to whatever backup scheme you're using.
- **Public IMAP.** Currently tailnet-only. To open it: add :993 to
  `mail-stream.nix` with `proxy_protocol on` and to homura's firewall
  `allowedTCPPorts`. Dovecot doesn't currently know about PROXY protocol
  — you'd need `haproxy_trusted_networks` + `inet_listener imaps { haproxy = yes }`.
- **Submission quota / rate limits.** comail enforces warming tier caps;
  postfix could also enforce per-tenant limits via `smtpd_client_rate_limit`
  and `smtpd_client_connection_count_limit` if any tenant gets noisy.
