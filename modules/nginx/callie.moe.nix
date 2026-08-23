{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme = {
    "owebui.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8097;
      target = "100.116.202.116"; 
      tailscaleOnly = true;
      extraLocationConfig = ''
        client_max_body_size 512M;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
      '';
    };

    "grafana.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 3000;
      target = "100.116.202.116"; 
      tailscaleOnly = true;
    };

    "home.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8123;
      target = "100.127.202.125"; 
      proxyWebsockets = true;
      proxyForwardHeaders = false;
      tailscaleOnly = true;
    };

    "flood.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 3001;
      target = "100.116.202.116";
    };

    "qb1.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8080;
      target = "100.116.202.116";
    };

    "qb2.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8080;
      target = "100.116.202.116";
    };

    "autobrr.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 7474;
      target = "100.116.202.116";
    };
  };
}
