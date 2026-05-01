{ config, self, ... }:
let
  cloudflareDNS = {
    dnsProvider = "cloudflare";
    environmentFile = config.age.secrets.cloudflare.path;
  };
  port8443 = [
    { addr = "[::]";    port = 8443; ssl = true; extraParameters = [ "http2" ]; }
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
in
{
  imports = [ ./vhost.nix ];

  age.secrets.cloudflare = {
    file = "${self}/secrets/cloudflare-dns.age";
    owner = "nginx";
    group = "nginx";
    mode = "400";
  };

  security.acme.certs."nematodes.net" = {
    domain = "nematodes.net";
    group = "nginx";
    inherit (cloudflareDNS) dnsProvider environmentFile;
  };

  services.nginx.virtualHosts."nematodes.net" = {
    forceSSL = true;
    listen = port8443;
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

  myServices.acme = {
    "navi.nematodes.net" = cloudflareDNS // {
      port = 4533;
      target = "100.102.158.29";
    };
    "x.nematodes.net" = cloudflareDNS // {
      port = 8067;
      target = "127.0.0.1";
    };
    "s3.nematodes.net" = cloudflareDNS // {
      port = 9000;
      target = "100.116.202.116";
      extraLocationConfig = "client_max_body_size 0;";
    };
    "llama.nematodes.net" = cloudflareDNS // {
      port = 8023;
      target = "100.116.202.116";
    };
    "book.nematodes.net" = cloudflareDNS // {
      port = 6969;
      target = "100.116.202.116";
      extraLocationConfig = "client_max_body_size 0;";
    };
    "auth.nematodes.net" = cloudflareDNS // {
      port = 9091;
      target = "100.116.202.116";
    };
  };
}
