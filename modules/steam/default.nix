{ pkgs, ... }:
{
  programs = {
    gamescope.enable = true;
    steam.enable     = true;
    gamemode.enable  = true;
  };

  environment.systemPackages = [ pkgs.mangohud ];
}
