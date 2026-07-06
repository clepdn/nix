{ lib, ... }:
{
  imports = [ ./homura-builder.nix ./signing.nix ];

  myNixOS.nix.homuraBuilder.enable = lib.mkDefault false;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "root" ];

      max-jobs = "auto";
      cores = 0;

      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly"; # or "daily", "monthly", a systemd calendar string like "Mon *-*-* 03:00:00", etc.
      options = "--delete-older-than 14d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  nixpkgs.config.allowUnfree = true;
}
