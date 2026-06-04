{ config, lib, pkgs, ... }:
let
  cfg = config.myNixOS.mail;

  # ---- Derived state -----------------------------------------------------
  # All domains we accept local delivery for, in postfix format.
  allDomains = lib.unique (
    [ cfg.primaryDomain ] ++ cfg.extraDomains
  );

  # All user@domain addresses, keyed by full address.
  # Used to build virtual_alias_maps and the dovecot passwd-file.
  allAddresses = lib.concatLists (lib.mapAttrsToList (name: u:
    let
      addrs = [ "${name}@${u.domain}" ] ++ u.aliases;
    in
      map (a: { address = a; user = name; }) addrs
  ) cfg.users);

  # postfix virtual map: "user@domain    localuser"
  virtualMap = lib.concatStringsSep "\n" (
    map (e: "${e.address}\t${e.user}") allAddresses
    ++ map (d: "postmaster@${d}\t${cfg.postmaster}") allDomains
    ++ map (d: "abuse@${d}\t${cfg.postmaster}") allDomains
  );

  # smtpd_sender_login_maps: which login may use which From address.
  # `user@domain    user@domain` — i.e. you must be authenticated as exactly
  # the From address you're submitting. (Stricter than allowing aliases; if
  # you want bob to be able to send as `b@domain`, add it to his aliases AND
  # he'll authenticate as `bob@domain` and that login owns `b@domain`.)
  senderLoginMap = lib.concatStringsSep "\n" (
    lib.concatMap (e: [
      # login that "owns" this address: the user's primary login (user@primary)
      "${e.address}\t${e.user}@${(cfg.users.${e.user}).domain}"
    ]) allAddresses
  );

  certDir = config.security.acme.certs.${cfg.host}.directory;

  vmailUid = 5000;
  vmailGid = 5000;

  # Path where dovecot reads the per-user passdb. Populated at activation
  # time by concatenating each user's bcrypt hash file.
  dovecotPasswdFile = "/run/dovecot2/passwd";
in
{
  options.myNixOS.mail = {
    enable = lib.mkEnableOption "multi-tenant mail (postfix + dovecot + comail relay)";

    host = lib.mkOption {
      type = lib.types.str;
      example = "mail.on-her.computer";
      description = "FQDN this MTA announces as itself. The TLS cert is issued for this name.";
    };

    primaryDomain = lib.mkOption {
      type = lib.types.str;
      example = "on-her.computer";
      description = ''
        The primary mail domain. Used for system mail (cron/root rewriting)
        and as the default `users.<name>.domain`.
      '';
    };

    extraDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional domains accepted for local delivery.";
    };

    postmaster = lib.mkOption {
      type = lib.types.str;
      description = "Local user that postmaster@/abuse@ aliases route to.";
    };

    acme.dnsProvider = lib.mkOption {
      type = lib.types.str;
      default = "cloudflare";
    };

    acme.environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "agenix path containing DNS-provider credentials for ACME.";
    };

    mailRoot = lib.mkOption {
      type = lib.types.path;
      default = "/var/vmail";
      description = "Root directory for virtual user maildirs.";
    };

    proxyProtocolFrom = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = [ "100.77.12.60" ];
      description = ''
        IPs allowed to speak PROXY protocol at our inbound smtpd on :25
        and the submission listener on :587. Typically the tailnet IP of
        the public stream-proxy host (sayaka).
      '';
    };

    relay = {
      host = lib.mkOption {
        type = lib.types.str;
        example = "smtp.atmos.email";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 587;
      };
      saslPasswdFile = lib.mkOption {
        type = lib.types.path;
        description = ''
          agenix path containing a postfix-format sasl_passwd line, e.g.:

              [smtp.atmos.email]:587 on-her.computer:atmos_XXXXXXXXXXXXXXXXXXXX
        '';
      };
    };

    users = lib.mkOption {
      description = "Mail users. The attribute name is the local part of the login.";
      default = {};
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            default = cfg.primaryDomain;
            description = "Domain this user lives on. Must be primaryDomain or in extraDomains.";
          };
          passwordHashFile = lib.mkOption {
            type = lib.types.path;
            description = ''
              agenix path containing a single bcrypt password hash, e.g. as
              produced by `doveadm pw -s BLF-CRYPT`. One line. No username,
              no trailing newline issues.
            '';
          };
          aliases = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = [ "alt@example.com" ];
            description = ''
              Additional full addresses (user@domain) that deliver to this
              user. The user authenticates as `<name>@<domain>` and is
              authorised by smtpd_sender_login_maps to send From: any alias.
            '';
          };
        };
      }));
    };
  };

  config = lib.mkIf cfg.enable {

    # =========================================================================
    # Sanity assertions
    # =========================================================================
    assertions = lib.mapAttrsToList (uname: u: {
      assertion = lib.elem u.domain allDomains;
      message = "myNixOS.mail.users.${uname}.domain (${u.domain}) is not in primaryDomain or extraDomains.";
    }) cfg.users ++ [
      { assertion = cfg.users ? ${cfg.postmaster};
        message = "myNixOS.mail.postmaster (${cfg.postmaster}) must be one of myNixOS.mail.users."; }
    ];

    # =========================================================================
    # Virtual mail user
    # =========================================================================
    users.users.vmail = {
      isSystemUser = true;
      group = "vmail";
      uid = vmailUid;
      home = cfg.mailRoot;
      createHome = false;
    };
    users.groups.vmail.gid = vmailGid;

    systemd.tmpfiles.rules =
      [ "d ${cfg.mailRoot} 0750 vmail vmail - -" ]
      ++ map (d: "d ${cfg.mailRoot}/${d} 0750 vmail vmail - -") allDomains
      ++ lib.mapAttrsToList (uname: u:
           "d ${cfg.mailRoot}/${u.domain}/${uname} 0700 vmail vmail - -"
         ) cfg.users;

    # =========================================================================
    # ACME cert
    # =========================================================================
    security.acme = {
      acceptTerms = true;
      certs.${cfg.host} = {
        domain = cfg.host;
        group = "acme";
        dnsProvider = cfg.acme.dnsProvider;
        environmentFile = cfg.acme.environmentFile;
        reloadServices = [ "postfix.service" "dovecot2.service" ];
      };
    };
    users.users.postfix.extraGroups  = [ "acme" ];
    users.users.dovecot2.extraGroups = [ "acme" ];

    # =========================================================================
    # Comail SASL credentials
    # =========================================================================
    systemd.services.postfix-sasl-passwd = {
      description = "Install comail SASL credentials for postfix";
      wantedBy = [ "postfix.service" ];
      before   = [ "postfix.service" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        install -d -m 0750 -o root -g postfix /var/lib/postfix/conf
        install -m 0640 -o root -g postfix \
          ${cfg.relay.saslPasswdFile} \
          /var/lib/postfix/conf/sasl_passwd
        ${pkgs.postfix}/bin/postmap hash:/var/lib/postfix/conf/sasl_passwd
        chmod 0640 /var/lib/postfix/conf/sasl_passwd.db
        chown root:postfix /var/lib/postfix/conf/sasl_passwd.db
      '';
    };

    # =========================================================================
    # Generic-maps: rewrite system mail (root@homura → postmaster@primary).
    # User-submitted mail already has a valid From; smtpd_sender_login_maps
    # enforces that they can only send what they own.
    # =========================================================================
    environment.etc."postfix/generic".text = lib.concatStringsSep "\n" ([
      "@${config.networking.hostName}        ${cfg.postmaster}@${cfg.primaryDomain}"
      "@${cfg.host}                          ${cfg.postmaster}@${cfg.primaryDomain}"
    ]);

    environment.etc."postfix/virtual".text = virtualMap + "\n";
    environment.etc."postfix/sender_login".text = senderLoginMap + "\n";
    environment.etc."postfix/smtp_header_checks".text = ''
      /^Received:.*/                IGNORE
      /^User-Agent:.*/              IGNORE
      /^X-Mailer:.*/                IGNORE
      /^X-Originating-IP:.*/        IGNORE
    '';

    system.activationScripts.postfix-mail-maps = lib.stringAfter [ "etc" ] ''
      ${pkgs.postfix}/bin/postmap hash:/etc/postfix/generic
      ${pkgs.postfix}/bin/postmap hash:/etc/postfix/virtual
      ${pkgs.postfix}/bin/postmap hash:/etc/postfix/sender_login
    '';

    # =========================================================================
    # Postfix
    # =========================================================================
    services.postfix = {
      enable = true;

      # We manage virtual and sender_login as raw map files above (so they
      # update on tenant changes without a postfix service restart). Don't
      # use services.postfix.virtual here — it conflicts.
      enableSubmission  = true;
      enableSubmissions = false;   # no 465; submission is 587 STARTTLS only

      # Submission listener: SASL via dovecot, force From == authenticated id,
      # require encryption, accept PROXY protocol from the public fronter.
      submissionOptions = {
        smtpd_tls_security_level     = "encrypt";
        smtpd_sasl_auth_enable       = "yes";
        smtpd_sasl_type              = "dovecot";
        smtpd_sasl_path              = "private/auth";
        smtpd_sasl_security_options  = "noanonymous";
        smtpd_sasl_local_domain      = "";
        smtpd_client_restrictions    = "permit_sasl_authenticated,reject";
        smtpd_sender_login_maps      = "hash:/etc/postfix/sender_login";
        smtpd_sender_restrictions    = "reject_sender_login_mismatch,permit_sasl_authenticated,reject";
        smtpd_recipient_restrictions = "permit_sasl_authenticated,reject";
        smtpd_relay_restrictions     = "permit_sasl_authenticated,reject";
        # Accept PROXY protocol from sayaka.
        smtpd_upstream_proxy_protocol = "haproxy";
        smtpd_upstream_proxy_timeout  = "5s";
        # Tighten what cleanup adds
        cleanup_service_name         = "cleanup";
      };

      settings.main = {
        # ---- Identity ----
        myhostname    = cfg.host;
        mydomain      = cfg.primaryDomain;
        myorigin      = cfg.primaryDomain;
        mydestination = [ "localhost" ];      # virtual handles real mail

        # ---- Virtual delivery via dovecot LMTP ----
        virtual_alias_domains  = allDomains;
        virtual_alias_maps     = [ "hash:/etc/postfix/virtual" ];
        virtual_transport      = "lmtp:unix:private/dovecot-lmtp";
        mailbox_transport      = "lmtp:unix:private/dovecot-lmtp";
        # local_transport for the rare case anything tries `mydestination`
        local_transport        = "error:local delivery is disabled";

        # ---- TLS ----
        smtpd_tls_chain_files    = [ "${certDir}/full.pem" ];
        smtpd_tls_security_level = "may";
        smtp_tls_security_level  = "encrypt";
        smtp_tls_wrappermode     = false;

        # ---- PROXY protocol on :25 from public fronter only ----
        # (Submission's own listener also accepts it, configured in
        #  submissionOptions above.)
        smtpd_upstream_proxy_protocol = "haproxy";
        smtpd_upstream_proxy_timeout  = "5s";
        mynetworks = [ "127.0.0.0/8" "[::1]/128" ]
          ++ map (ip: "${ip}/32") cfg.proxyProtocolFrom;

        # ---- Inbound recipient restrictions on :25 ----
        smtpd_recipient_restrictions = lib.concatStringsSep "," [
          "permit_mynetworks"
          "reject_unauth_destination"
        ];
        smtpd_relay_restrictions = "reject_unauth_destination";

        # ---- Outbound to comail ----
        relayhost                      = [ "[${cfg.relay.host}]:${toString cfg.relay.port}" ];
        smtp_sasl_auth_enable          = true;
        smtp_sasl_password_maps        = "hash:/var/lib/postfix/conf/sasl_passwd";
        smtp_sasl_security_options     = "noanonymous";
        smtp_sasl_tls_security_options = "noanonymous";
        smtp_tls_note_starttls_offer   = true;

        # ---- Rewrite system mail; strip identifying headers ----
        smtp_generic_maps   = "hash:/etc/postfix/generic";
        smtp_header_checks  = "regexp:/etc/postfix/smtp_header_checks";

        # ---- Hygiene ----
        message_size_limit   = 52428800;
        smtpd_helo_required  = true;
        disable_vrfy_command = true;
      };
    };

    # =========================================================================
    # Dovecot — virtual users via passwd-file, LMTP for postfix, IMAP for clients
    # =========================================================================
    # Build the passwd file from each user's bcrypt hash secret at boot.
    # Format: "user@domain:{BLF-CRYPT}$2y$.....:5000:5000::/var/vmail/domain/user::"
    systemd.services.dovecot-passwd = {
      description = "Assemble dovecot virtual-user passwd file";
      wantedBy = [ "dovecot2.service" ];
      before   = [ "dovecot2.service" ];
      serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
      script = ''
        install -d -m 0750 -o root -g dovecot2 /run/dovecot2
        tmp="$(mktemp)"
        ${lib.concatMapStringsSep "\n" (uname:
          let u = cfg.users.${uname}; in ''
            hash="$(cat ${u.passwordHashFile})"
            printf '%s@%s:%s:${toString vmailUid}:${toString vmailGid}::${cfg.mailRoot}/%s/%s::\n' \
              ${lib.escapeShellArg uname} ${lib.escapeShellArg u.domain} "$hash" \
              ${lib.escapeShellArg u.domain} ${lib.escapeShellArg uname} \
              >> "$tmp"
          ''
        ) (lib.attrNames cfg.users)}
        install -m 0640 -o root -g dovecot2 "$tmp" ${dovecotPasswdFile}
        rm -f "$tmp"
      '';
    };

    services.dovecot2 = {
      enable    = true;
      enablePAM = false;   # we authenticate against the passwd-file above

      settings = {
        protocols.imap = true;
        protocols.lmtp = true;
        protocols.pop3 = false;

        ssl_cert = "<${certDir}/fullchain.pem";
        ssl_key  = "<${certDir}/key.pem";

        # Virtual-user mail location. %d = domain, %n = local part.
        mail_location = "maildir:${cfg.mailRoot}/%d/%n";
        mail_uid = "vmail";
        mail_gid = "vmail";
        first_valid_uid = vmailUid;
        last_valid_uid  = vmailUid;

        auth_mechanisms = [ "plain" "login" ];

        # IMAP binds everywhere; firewall confines IMAP to the tailnet.
        listen = "*, ::";

        "namespace inbox" = {
          inbox = true;
          separator = "/";
          "mailbox Trash"  = { auto = "subscribe"; special_use = "\\Trash";  };
          "mailbox Sent"   = { auto = "subscribe"; special_use = "\\Sent";   };
          "mailbox Drafts" = { auto = "subscribe"; special_use = "\\Drafts"; };
          "mailbox Junk"   = { auto = "subscribe"; special_use = "\\Junk";   };
        };

        passdb = {
          driver = "passwd-file";
          args = "scheme=BLF-CRYPT username_format=%u ${dovecotPasswdFile}";
        };
        userdb = {
          driver = "passwd-file";
          args = "username_format=%u ${dovecotPasswdFile}";
        };

        # LMTP socket inside postfix's chroot ($queue_directory/private/).
        # Postfix delivers to this socket via the virtual_transport above.
        "service lmtp" = {
          "unix_listener /var/lib/postfix/queue/private/dovecot-lmtp" = {
            mode  = "0600";
            user  = "postfix";
            group = "postfix";
          };
        };

        # SASL auth socket for postfix submission. Same chroot path trick.
        "service auth" = {
          "unix_listener /var/lib/postfix/queue/private/auth" = {
            mode  = "0660";
            user  = "postfix";
            group = "postfix";
          };
        };
      };
    };

    # =========================================================================
    # Firewall
    # =========================================================================
    # :25 and :587 only from the public fronter (PROXY-wrapped).
    # :993 / :143 (IMAP) only from tailscale interface.
    networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 993 143 ];
    networking.firewall.extraInputRules = lib.concatMapStringsSep "\n" (ip: ''
      ip saddr ${ip} tcp dport { 25, 587 } accept
    '') cfg.proxyProtocolFrom;
  };
}
