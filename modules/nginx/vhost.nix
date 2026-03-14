{ config, lib, ... }:
let cfg = config.myServices.acme;
  port8443 = [
    { addr = "[::]";   port = 8443; ssl = true;  extraParameters = [ "http2" ]; }
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

  authentikOutpost = "https://auth.on-her.computer/outpost.goauthentik.io/auth/nginx";

  forwardAuthConfig = ''
    auth_request /outpost.goauthentik.io/auth/nginx;
    error_page 401 = @authentik_start;

    auth_request_set $authentik_set_cookie $upstream_http_set_cookie;
    add_header Set-Cookie $authentik_set_cookie;

    auth_request_set $authentik_username $upstream_http_x_authentik_username;
    auth_request_set $authentik_groups $upstream_http_x_authentik_groups;
    auth_request_set $authentik_email $upstream_http_x_authentik_email;
    auth_request_set $authentik_name $upstream_http_x_authentik_name;
    auth_request_set $authentik_uid $upstream_http_x_authentik_uid;

    proxy_set_header X-authentik-username $authentik_username;
    proxy_set_header X-authentik-groups $authentik_groups;
    proxy_set_header X-authentik-email $authentik_email;
    proxy_set_header X-authentik-name $authentik_name;
    proxy_set_header X-authentik-uid $authentik_uid;
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
      options.extraLocationConfig = lib.mkOption { 
        type = lib.types.str; 
        default = "";
      };
      options.wildcard = lib.mkOption { type = lib.types.bool; default = false; };
      options.forwardAuth = lib.mkOption { type = lib.types.bool; default = false; };
    });
    default = {};
  };

  config = {
    security.acme.certs = lib.mapAttrs (name: opts: {
      domain = if opts.wildcard then "*.${name}" else name;
      extraDomainNames = [ name ];
      group = "nginx";
      dnsProvider = opts.dnsProvider;
      environmentFile = opts.environmentFile;
    }) cfg;

    services.nginx.virtualHosts = lib.listToAttrs (lib.flatten (lib.mapAttrsToList (name: opts:
    let mkVhost = n: lib.nameValuePair n ({
      forceSSL = true;
      listen = port8443;
      useACMEHost = name;
      locations."/" = {
        proxyPass = "http://${opts.target}:${toString opts.port}";
        extraConfig = commonProxyHeaders + "\n" + opts.extraLocationConfig
          + lib.optionalString opts.forwardAuth ("\n" + forwardAuthConfig);
      };
    } // lib.optionalAttrs opts.forwardAuth {
      locations."/outpost.goauthentik.io" = {
        proxyPass = "https://auth.on-her.computer/outpost.goauthentik.io";
        extraConfig = commonProxyHeaders;
      };
      extraConfig = ''
        error_page 401 = @authentik_start;
        location @authentik_start {
          internal;
          return 302 https://auth.on-her.computer/outpost.goauthentik.io/start?rd=$scheme://$http_host$request_uri;
        }
      '';
    } // opts.extraNginxOpts);
    in 
      if opts.wildcard
      then [ (mkVhost name) (mkVhost "*.${name}") ]
      else [ (mkVhost name) ]
      ) cfg));
  };
}
