{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme = {
    "pi.callie.moe" = config.myNixOS.cloudflareDns // {
      port = 8180;
      target = "100.116.202.116";
      tailscaleOnly = true;
    };
  };
}
