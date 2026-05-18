{ config, ... }:
let
  port443 = [
    { addr = "[::]";    port = 443; ssl = true; extraParameters = [ "http2" ]; }
    { addr = "0.0.0.0"; port = 443; ssl = true; extraParameters = [ "http2" ]; }
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
in
{
  imports = [ ./vhost.nix ];

  security.acme.certs."nematodes.net" = {
    domain = "nematodes.net";
    group = "nginx";
    inherit (config.myNixOS.cloudflareDns) dnsProvider environmentFile;
  };

  services.nginx.virtualHosts."nematodes.net" = {
    forceSSL = true;
    listen = port443;
    useACMEHost = "nematodes.net";
    locations = {
      "/booru" = {
        return = "302 $scheme://$host/booru/";
      };
      "/booru/" = {
        extraConfig = ''
          autoindex on;
          error_page 404 =200 "/booru/index.html";
          alias /var/www/booru/;
        '';
      };
      "/restart" = {
        proxyPass = "http://100.116.202.116:9097/hooks/restart-comfymc";
        extraConfig = commonProxyHeaders;
      };
      "/jellyfin" = {
        return = "302 $scheme://$host/jellyfin/";
      };
      "/jellyfin/" = {
        proxyPass = "http://100.80.201.30:8096";
        extraConfig = commonProxyHeaders;
      };
      "~ ^/germ/.+" = {
        return = "302 https://signal.org/download";
      };
      "/" = {
        root = "/var/www/nematodes/";
        index = "index.html";
      };
    };
  };

  myNixOS.acme = {
    "navi.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 4533;
      target = "100.102.158.29";
    };
    "x.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 8067;
      target = "127.0.0.1";
    };
    "s3.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 9000;
      target = "100.116.202.116";
      extraLocationConfig = "client_max_body_size 0;";
    };
    "llama.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 8023;
      target = "100.116.202.116";
    };
    "book.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 6969;
      target = "100.116.202.116";
      extraLocationConfig = "client_max_body_size 0;";
    };
    "auth.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 9091;
      target = "100.116.202.116";
    };
    "em.nematodes.net" = config.myNixOS.cloudflareDns // {
      port = 7681;
      target = "100.116.202.116";
    };
  };
}
