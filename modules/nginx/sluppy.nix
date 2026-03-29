{ config, lib, self, ... }:
let
  cloudflareDNS = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare.path;
  };

  pds = config.services.pds;

  middlewareLocations = lib.listToAttrs (map (route: {
    name  = "= /xrpc/${route}";
    value = {
      proxyPass = "http://${pds.middleware.address}:${toString pds.middleware.port}";
      extraConfig = ''
        proxy_pass_request_headers on;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $http_host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $http_connection;
        proxy_buffering off;
        client_max_body_size 2G;
      '';
    };
  }) pds.middleware.routes);
in
{
  imports = [
    ./vhost.nix
    ../pds
  ];

  age.secrets.cloudflare = {
    file = "${self}/secrets/cloudflare-dns.age";
    owner = "nginx";
    group = "nginx";
    mode = "400";
  };

  age.secrets.pds-env = {
    file = "${self}/secrets/pds.env.age";
    mode = "400";
  };

  services.pds = {
    enable = true;
    hostname = "pds.sluppy.moe";
    environmentFile = config.age.secrets.pds-env.path;
    middleware = {
      address = "100.116.202.116";
      port = 4004;
      routes = [
        "com.atproto.repo.createRecord"
        "com.atproto.repo.deleteRecord"
        "com.atproto.repo.putRecord"
        "com.atproto.repo.applyWrites"
        "com.atproto.repo.importRepo"
      ];
    };
  };

  myServices.acme."pds.sluppy.moe" = cloudflareDNS // {
    port = pds.port;
    target = "127.0.0.1";
    wildcard = true;
    extraLocationConfig = ''client_max_body_size 2G;'';
    extraNginxOpts.locations = middlewareLocations;
  };
}
