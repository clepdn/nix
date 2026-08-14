{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme = {
    "owebui.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8097;
      target = "100.116.202.116"; # homura — open-webui
      tailscaleOnly = true;
      extraLocationConfig = ''
        client_max_body_size 512M;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
      '';
    };
    "grafana.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 3000;
      target = "100.116.202.116"; # homura — Grafana
      tailscaleOnly = true;
    };

    "home.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8123;
      target = "100.127.202.125"; # lightbulb — Home Assistant
      proxyWebsockets = true;
      proxyForwardHeaders = false;
      tailscaleOnly = true;
    };
  };
}
