{ config, lib, self, ... }:
let cfg = config.myNixOS.acme;
  port443 = [
    { addr = "[::]";    port = 443; ssl = true;  extraParameters = [ "http2" ]; }
    { addr = "0.0.0.0"; port = 443; ssl = true; extraParameters = [ "http2" ]; }
  ];

  # Tailscale-only hosts must share the wildcard listener with public hosts.
  # Binding an exact Tailscale address makes Nginx select that server before
  # SNI, so unrelated hosts such as flood.callie.moe get the wrong backend.
  tailscaleAccess = ''
    allow 100.64.0.0/10;
    allow fd7a:115c:a1e0::/48;
    deny all;
  '';

  commonProxyHeaders = forwardHeaders: ''
    proxy_pass_request_headers on;
    proxy_set_header Host $host;
    ${lib.optionalString forwardHeaders ''
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $http_host;
    ''}
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_buffering off;
  '';

in {
  options.myNixOS.cloudflareDns = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    readOnly = true;
    default = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare.path;
      # Sayaka's Tailnet resolver is authoritative for private subdomains.
      # ACME must discover and verify the public Cloudflare zone instead.
      dnsResolver = "1.1.1.1:53";
    };
  };

  options.myNixOS.porkbunDns = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    readOnly = true;
    default = {
      dnsProvider = "porkbun";
      environmentFile = config.age.secrets.porkbun.path;
    };
  };

  options.myNixOS.acme = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.port            = lib.mkOption { type = lib.types.port; };
      options.target          = lib.mkOption { type = lib.types.str;  };
      options.dnsProvider     = lib.mkOption { type = lib.types.str;  };
      options.environmentFile = lib.mkOption { type = lib.types.str;  };
      options.dnsResolver     = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      options.extraNginxOpts  = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
      options.extraServerConfig = lib.mkOption { type = lib.types.str; default = ""; };

      options.extraLocationConfig = lib.mkOption { 
        type = lib.types.str; 
        default = "";
      };

      options.proxyWebsockets = lib.mkOption { type = lib.types.bool; default = false; };

      options.proxyForwardHeaders = lib.mkOption { type = lib.types.bool; default = true; };

      options.wildcard      = lib.mkOption { type = lib.types.bool; default = false; };
      options.tailscaleOnly = lib.mkOption { type = lib.types.bool; default = false; };
    });
    default = {};
  };

  config = {
    age.secrets.cloudflare = {
      file = "${self}/secrets/cloudflare-dns.age";
      owner = "nginx";
      group = "nginx";
      mode = "400";
    };

    age.secrets.porkbun = {
      file = "${self}/secrets/porkbun-dns.age";
      owner = "nginx";
      group = "nginx";
      mode = "400";
    };

    security.acme.certs = lib.mapAttrs (name: opts: {
      domain = if opts.wildcard then "*.${name}" else name;
      extraDomainNames = [ name ];
      group = "nginx";
      dnsProvider = opts.dnsProvider;
      environmentFile = opts.environmentFile;
      dnsResolver = opts.dnsResolver;
    }) cfg;

    services.nginx.virtualHosts = lib.listToAttrs (lib.flatten (lib.mapAttrsToList (name: opts:
    let
      baseVhost = {
        forceSSL = true;
        listen = port443;
        useACMEHost = name;
        locations."/" = {
          proxyPass = "http://${opts.target}:${toString opts.port}";
          proxyWebsockets = opts.proxyWebsockets;
          extraConfig = (commonProxyHeaders opts.proxyForwardHeaders) + "\n" + opts.extraLocationConfig;
        };
        extraConfig =
          (lib.optionalString opts.tailscaleOnly tailscaleAccess)
          + opts.extraServerConfig;
      };
      mkVhost = n: lib.nameValuePair n
        (lib.recursiveUpdate baseVhost opts.extraNginxOpts);
    in
      if opts.wildcard
      then [ (mkVhost name) (mkVhost "*.${name}") ]
      else [ (mkVhost name) ]
      ) cfg));
  };
}
