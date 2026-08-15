{ config, lib, ... }:

let
  cfg = config.myNixOS.podman;
in
{
  options.myNixOS.podman.enable = lib.mkEnableOption "Podman OCI containers";

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };

    virtualisation.oci-containers.backend = "podman";
  };
}
