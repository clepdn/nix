{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme = {
    "bridget.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 4040;
      target = "100.116.202.116";
      proxyWebsockets = true;
      extraLocationConfig = ''
        client_max_body_size 100M;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_cache off;
        chunked_transfer_encoding off;
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

    /* Dead for some reason
    "cobalt.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 9000;
      target = "100.102.158.29";
    };
    */
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
  };
}
