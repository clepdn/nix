{ self, ... }:
{
  imports = [
    "${self}/modules/niri"
  ];

  myNixOS.niri.idle.sleep = {
    enable = true;
  };

  home-manager.users.callie.programs.niri.settings.outputs."eDP-1" = {
    mode = { width = 1920; height = 1200; refresh = 59.950; };
    scale = 1.25;
  };
}
