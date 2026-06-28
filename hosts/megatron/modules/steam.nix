{ pkgs, ... }:
{
  programs = {
    gamescope.enable = true;
    steam.enable     = true;
    # `gamemoderun %command%` in a Steam launch option pins the CPU governor,
    # raises IO priority, and tells the compositor to back off.
    gamemode.enable  = true;
  };

  # mangohud overlay (MANGOHUD=1) is the only realistic FPS/frametime readout
  # under GSP-RM, since hwmon is unavailable.
  environment.systemPackages = [ pkgs.mangohud ];
}
