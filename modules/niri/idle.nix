{ config, pkgs, lib, ... }:
let
  cfg = config.myNixOS.niri.idle;

  timeouts = [
    { seconds = cfg.lockTimeout; command = "swaylock -f"; }
    { seconds = cfg.dpmsTimeout; command = "niri msg action power-off-monitors"; }
  ] ++ lib.optional cfg.sleep.enable {
    seconds = cfg.sleep.timeout;
    command = cfg.sleep.command;
  };

  timeoutArgs =
    lib.concatMapStringsSep " "
      (t: "timeout ${toString t.seconds} '${t.command}'")
      timeouts;

  swayidleCmd = lib.concatStringsSep " " [
    "${pkgs.swayidle}/bin/swayidle -w"
    timeoutArgs
    "resume 'niri msg action power-on-monitors'"
    "before-sleep 'swaylock -f'"
    "lock 'swaylock -f'"
  ];
in
{
  options.myNixOS.niri.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 300;
      description = "Seconds of idle before the session locks (swaylock).";
    };

    dpmsTimeout = lib.mkOption {
      type = lib.types.int;
      default = 360;
      description = "Seconds of idle before the monitors are powered off (DPMS).";
    };

    sleep = {
      enable = lib.mkEnableOption ''
        putting the machine to sleep after an idle timeout in the niri
        session, via an extra swayidle timeout. Disabled by default so
        desktops sharing this module don't auto-suspend.
      '';

      timeout = lib.mkOption {
        type = lib.types.int;
        default = 600;
        description = "Seconds of idle before the sleep command runs.";
      };

      command = lib.mkOption {
        type = lib.types.str;
        default = "systemctl suspend-then-hibernate";
        description = ''
          Command run when the idle sleep timeout elapses. It runs in the
          user session, so it must be something logind lets the active
          user invoke without extra privileges.
        '';
      };
    };
  };

  config = {
    systemd.user.services.swayidle = {
      description = "swayidle idle manager (lock + DPMS) for niri";
      wantedBy = [ "niri.service" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      path = [ config.programs.niri.package pkgs.swaylock ];
      serviceConfig = {
        Type = "simple";
        ExecStart = swayidleCmd;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
