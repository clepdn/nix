{ ... }:
{
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
