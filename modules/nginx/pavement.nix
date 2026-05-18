{ config, ... }:
{
  imports = [
    ./vhost.nix
  ];

  myNixOS.acme."underthepavement.net" = config.myNixOS.cloudflareDns // {
    port = 3400;
    target = "100.77.12.60";
    extraLocationConfig = ''client_max_body_size 500M;'';
  };
}
