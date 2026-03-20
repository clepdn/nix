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

  autheliaAddr = "https://au.on-her.computer";

  forwardAuthConfig = ''
    auth_request /internal/authelia/authz;

    auth_request_set $redirection_url $upstream_http_location;

    auth_request_set $user   $upstream_http_remote_user;
    auth_request_set $groups $upstream_http_remote_groups;
    auth_request_set $name   $upstream_http_remote_name;
    auth_request_set $email  $upstream_http_remote_email;

    proxy_set_header Remote-User   $user;
    proxy_set_header Remote-Groups $groups;
    proxy_set_header Remote-Name   $name;
    proxy_set_header Remote-Email  $email;

    error_page 401 =302 $redirection_url;
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
    let
      baseVhost = {
        forceSSL = true;
        listen = port8443;
        useACMEHost = name;
        locations."/" = {
          proxyPass = "http://${opts.target}:${toString opts.port}";
          extraConfig = commonProxyHeaders + "\n" + opts.extraLocationConfig
            + lib.optionalString opts.forwardAuth ("\n" + forwardAuthConfig);
        };
      };
      autheliaVhost = lib.optionalAttrs opts.forwardAuth {
        locations."/internal/authelia/authz" = {
          proxyPass = "${autheliaAddr}/api/authz/auth-request";
          extraConfig = ''
            internal;
            proxy_pass_request_body off;
            proxy_set_header Content-Length "";
            proxy_set_header Connection "";
            proxy_set_header X-Original-Method $request_method;
            proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
            proxy_set_header X-Forwarded-For $remote_addr;
          '';
        };
      };
      mkVhost = n: lib.nameValuePair n
        (lib.recursiveUpdate (lib.recursiveUpdate baseVhost autheliaVhost) opts.extraNginxOpts);
    in 
      if opts.wildcard
      then [ (mkVhost name) (mkVhost "*.${name}") ]
      else [ (mkVhost name) ]
      ) cfg));
  };
}
