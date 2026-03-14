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

  oauth2ProxyAddr = "http://100.116.202.116:4180";

  forwardAuthConfig = ''
    auth_request /oauth2/auth;

    auth_request_set $user  $upstream_http_x_auth_request_user;
    auth_request_set $email $upstream_http_x_auth_request_email;
    auth_request_set $auth_cookie $upstream_http_set_cookie;

    proxy_set_header X-User  $user;
    proxy_set_header X-Email $email;
    add_header Set-Cookie $auth_cookie;
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
      locations."/oauth2/" = {
        proxyPass = "${oauth2ProxyAddr}/oauth2/";
        extraConfig = commonProxyHeaders + ''
          proxy_set_header X-Scheme $scheme;
          proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
          auth_request off;
        '';
      };
      extraConfig = ''
        error_page 401 = @oauth2_login;
        location @oauth2_login {
          internal;
          return 302 ${oauth2ProxyAddr}/oauth2/start?rd=$scheme://$host$request_uri;
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
