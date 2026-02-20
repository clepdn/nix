{ config, pkgs, lib, inputs, ... }:
{
  users.users.callie = {
    isNormalUser = true;
    description = "Callie";
    extraGroups = [ "networkmanager" "wheel" "input" "video" ];
    shell = pkgs.fish;
    hashedPassword = "$y$j9T$ZJuNNt8D4FZIqVGqytHP31$tE9z6v5nFb7XSUzFKcqEmKlidCjhhRyLDx.WJh9gD.6";
    packages = with pkgs; [
      kdePackages.kate
      inputs.zen-browser.packages."${pkgs.system}".default
      qdirstat
      feishin
      thunderbird
    ];
  };

  home-manager.users.callie = { pkgs, ... }: {
    home = {
      homeDirectory = config.users.users.callie.home;
      # packages =
      stateVersion = "25.11";
     };
  };

  programs.fish.enable = true;

  nix.settings.trusted-users = [ "callie" ];
}
