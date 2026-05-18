{ lib, ... }:
{
  imports = [ ./homura-builder.nix ];

  # Enable homura as a remote builder on all machines by default.
  # Opt out with: myNixOS.nix.homuraBuilder.enable = false;
  myNixOS.nix.homuraBuilder.enable = lib.mkDefault true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly"; # or "daily", "monthly", a systemd calendar string like "Mon *-*-* 03:00:00", etc.
    options = "--delete-older-than 14d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  nix.settings.auto-optimise-store = true;

  nixpkgs.config.allowUnfree = true;
}
