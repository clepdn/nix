{ config, self, ... }:
{
  imports = [ "${self}/modules/mail" ];

  # Cloudflare credentials for ACME DNS-01. We re-declare the secret here
  # with acme ownership so this module is self-contained even on hosts that
  # don't run nginx.
  age.secrets.cloudflare-acme-mail = {
    file = "${self}/secrets/cloudflare-dns.age";
    owner = "acme";
    group = "acme";
    mode = "400";
  };

  # Comail SASL credentials. File format (one line, no trailing context):
  #     [smtp.atmos.email]:587 on-her.computer:atmos_XXXXXXXXXXXXXXXXXXXX
  age.secrets.comail-sasl = {
    file = "${self}/secrets/comail-sasl.age";
    owner = "root";
    group = "root";
    mode = "400";
  };

  # Per-tenant bcrypt password hashes. Generate with:
  #     doveadm pw -s BLF-CRYPT -p '<password>'
  # then strip the leading "{BLF-CRYPT}" — the passdb scheme= option below
  # already prepends it. File contents: a single line, the hash starting
  # with "$2y$..." (or include "{BLF-CRYPT}$2y$..."; dovecot accepts both).
  age.secrets."mail-passwd-callie" = {
    file = "${self}/secrets/mail-passwd-callie.age";
    owner = "root";
    group = "root";
    mode = "400";
  };

  myNixOS.mail = {
    enable = true;
    host          = "mail.on-her.computer";
    primaryDomain = "on-her.computer";
    extraDomains  = [];                  # add more domains here
    postmaster    = "callie";

    acme.environmentFile = config.age.secrets.cloudflare-acme-mail.path;

    # sayaka stream-proxies inbound :25 and :587 with PROXY protocol.
    proxyProtocolFrom = [ "100.77.12.60" ];

    relay = {
      host = "smtp.atmos.email";
      port = 587;
      saslPasswdFile = config.age.secrets.comail-sasl.path;
    };

    users = {
      callie = {
        # domain defaults to primaryDomain
        passwordHashFile = config.age.secrets."mail-passwd-callie".path;
      };
      # Add tenants here:
      # bob = {
      #   passwordHashFile = config.age.secrets."mail-passwd-bob".path;
      #   aliases = [ "robert@on-her.computer" ];
      # };
    };
  };
}
