{ config, lib, self, ... }:
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
    age.secrets.nix-remote-builder-key = {
      file = "${self}/secrets/nix-remote-builder-key.age";
      mode = "0400";
      owner = "root";
    };

    # Pre-trust homura's SSH host key so the nix daemon can connect unattended.
    programs.ssh.knownHosts."100.116.202.116".publicKey =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBfMza/8Zl74EwMcdRv0FVfV68NBXIAN74OOsPlhNCZ4";

    nix.distributedBuilds = true;

    nix.buildMachines = [{
      hostName = "100.116.202.116"; # homura tailscale IP
      sshUser = "nix-remote-builder";
      sshKey = config.age.secrets.nix-remote-builder-key.path;
      system = "x86_64-linux";
      maxJobs = cfg.maxJobs;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }];

    nix.settings.builders-use-substitutes = true;
  };
}
