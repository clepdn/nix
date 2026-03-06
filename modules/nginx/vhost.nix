{ config, lib, ... }:
let cfg = config.myServices.acme;
  port8443 = [
    { addr = "[::]";   port = 8443; ssl = true; extraParameters = [ "http2" ]; }
    { addr = "0.0.0.0"; port = 8443; ssl = true; extraParameters = [ "http2" ]; }
  ];
  
  commonProxyHeaders = ''
    proxy_pass_request_headers on;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_buffering off;
  '';
in {
  options.myServices.acme = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.port = lib.mkOption { type = lib.types.port; };
      options.target = lib.mkOption { type = lib.types.str; };
      options.dnsProvider = lib.mkOption { type = lib.types.str; };
      options.environmentFile = lib.mkOption { type = lib.types.str; };
      options.extraNginxOpts = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
      options.extraLocationConfig = lib.mkOption { type = lib.types.str; };
    });
    default = {};
  };

  config = {
    security.acme.certs = lib.mapAttrs (name: opts: {
      domain = name;
      extraDomainNames = [ name ];
      group = "nginx";
    }) cfg;

    services.nginx.virtualHosts = lib.mapAttrs (name: opts: {
      forceSSL = true;
      listen = port8443; # Listen on internal upstream proxied HTTP port. Eventually translated to 443 upstream.
      useACMEHost = name;
      locations."/" = {
        proxyPass = "http://${opts.target}:${opts.port}";
        extraConfig = commonProxyHeaders + "\n" + opts.extraLocationConfig;
      };
    } // opts.extraNginxOpts) cfg;
  };
}
