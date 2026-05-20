{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme = {
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
    "cubit.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8080;
      target = "100.116.202.116";
      forwardAuth = true;
    };
    "tv.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8096;
      target = "100.116.202.116";
    };
    "home.on-her.computer" = config.myNixOS.cloudflareDns // {
      port = 8123;
      target = "100.116.202.116";
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
