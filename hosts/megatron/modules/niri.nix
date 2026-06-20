{ self, ... }:
{
  imports = [
    "${self}/modules/niri"
  ];

  home-manager.users.callie.programs.niri.settings.outputs = {
    "DP-1" = {
      mode = { width = 2560; height = 1440; refresh = 143.998; };
      scale = 1.25;
      transform = "normal";
      position = { x = 1920; y = 0; };
    };
    "DP-3" = {
      mode = { width = 2560; height = 1440; refresh = 143.998; };
      scale = 1.25;
      transform = "normal";
      position = { x = 0; y = 0; };
      variable-refresh-rate = true;
    };
  };
}
