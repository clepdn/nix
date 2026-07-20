{ self, ... }:
{
  imports = [
    "${self}/modules/niri"
  ];

  # Go to sleep after 10 min idle. suspend-then-hibernate (the systemd
  # default sleep command) suspends first, then hibernates once
  # systemd.sleep HibernateDelaySec elapses.
  myNixOS.niri.idle.sleep.enable = true;

  home-manager.users.callie.programs.niri.settings.outputs."eDP-1" = {
    mode = { width = 1920; height = 1200; refresh = 59.950; };
    scale = 1.25;
  };
}
