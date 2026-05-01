{ config, lib, ... }:
let
  cfg = config.myNixOS.nix.homuraBuilder;
in
{
  options.myNixOS.nix.homuraBuilder = {
    enable = lib.mkEnableOption "Use homura as a remote Nix build machine";
    maxJobs = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Max derivation builds to offload to homura.";
    };
  };

  config = lib.mkIf cfg.enable {
    nix.distributedBuilds = true;

    nix.buildMachines = [{
      hostName = "homura";
      system = "x86_64-linux";
      maxJobs = cfg.maxJobs;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }];

    nix.settings.builders-use-substitutes = true;
  };
}
