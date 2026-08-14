{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme = {
    "home.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8123;
      target = "100.127.202.125"; # lightbulb — Home Assistant
      proxyWebsockets = true;
      # Home Assistant rejects forwarded client headers until its mutable
      # configuration explicitly trusts Sayaka as a reverse proxy.
      extraLocationConfig = ''proxy_set_header X-Forwarded-For "";'';
      tailscaleOnly = true;
    };
    "grafana.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 3000;
      target = "100.116.202.116"; # homura — Grafana
      tailscaleOnly = true;
    };
    "bridget.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 4040;
      target = "100.116.202.116"; # homura — llm-bridge
      proxyWebsockets = true;
      extraLocationConfig = ''
        client_max_body_size 100M;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_cache off;
        chunked_transfer_encoding off;
      '';
    };
    "chat.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8097;
      target = "100.116.202.116"; # homura — open-webui
      extraLocationConfig = ''
        client_max_body_size 512M;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
      '';
    };
    "pds2.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 3084;
      target = "100.77.12.60";
      wildcard = true;
      extraLocationConfig = ''client_max_body_size 2G;'';
    };
    "pds.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 3000;
      target = "100.102.161.7";
      wildcard = true;
      extraLocationConfig = ''client_max_body_size 2G;'';
    };
    "pegasus.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 4000;
      target = "100.102.161.7";
      wildcard = true;
      extraLocationConfig = ''client_max_body_size 2G;'';
    };
    "cobalt.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 9000;
      target = "100.102.158.29";
    };
    "book.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 6969;
      target = "100.116.202.116";
      extraLocationConfig = ''client_max_body_size 10G;'';
    };
    "au.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 9091;
      target = "100.116.202.116";
    };
    "tv.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8096;
      target = "100.116.202.116";
      extraServerConfig = "ssl_protocols TLSv1.2 TLSv1.3;";
    };
    "lta.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8283;
      target = "100.116.202.116";
    };
    "gemma.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8020;
      target = "100.116.202.116";
    };
    "flood.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 3001;
      target = "100.116.202.116";
    };
    "brr.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 7474;
      target = "100.116.202.116";
    };
    "happy.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 3100;
      target = "100.116.202.116";
    };
  };
}
