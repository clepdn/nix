{ pkgs, ... }:
{
  programs.nix-ld.enable = true;
  system.activationScripts.binbash = "ln -sf ${pkgs.bashInteractive}/bin/bash /bin/bash";
}
