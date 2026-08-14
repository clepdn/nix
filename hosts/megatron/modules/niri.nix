{ self, pkgs, ... }:
{
  imports = [
    "${self}/modules/niri"
  ];

  myNixOS.niri.idle.sleep = {
    enable = true;
    command = "systemctl suspend";
  };

  systemd.user.services.awww-wallpaper = {
    description = "Hatsune Miku wallpaper";
    wantedBy = [ "niri.service" ];
    after = [ "awww-daemon.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.awww}/bin/awww img ${self}/assets/mirrored_green_offset_2560x1440_flipped.jpg";
    };
  };

  home-manager.users.callie.programs.niri.settings.outputs = {
    "DP-1" = {
      mode = { width = 2560; height = 1440; refresh = 143.998; };
      scale = 1.25;
      # transform = "normal";
      position = { x = 1920; y = 0; };
    };
    "DP-4" = {
      mode = { width = 2560; height = 1440; refresh = 143.998; };
      scale = 1.25;
      # transform = "normal";
      position = { x = 0; y = 0; };
      variable-refresh-rate = true;
    };
  };
}
