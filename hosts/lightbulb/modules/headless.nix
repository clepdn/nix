{ pkgs, ... }:
{
  # Turn the laptop backlight off at boot. lightbulb runs headless, so
  # leaving the panel lit just wastes power and produces glow.
  systemd.services.backlight-off = {
    description = "Turn off intel_backlight";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      Group = "root";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 0 > /sys/class/backlight/intel_backlight/brightness'";
    };
  };

  # Completely ignore the lid switch in all power states.
  services.logind = {
    lidSwitch = "ignore";
    lidSwitchExternalPower = "ignore";
    lidSwitchDocked = "ignore";
  };

  # Mask suspend so nothing (logind, dbus, GUI bits) can ever put the
  # machine to sleep.
  systemd.suppressedSystemUnits = [
    "suspend.target"
    "suspend-then-hibernate.target"
  ];
}
