{ config, pkgs, lib, ... }:
let
  cfg = config.myNixOS.niri.idle;
  dimBacklight = pkgs.writeShellApplication {
    name = "niri-dim-backlight";
    runtimeInputs = [ pkgs.brightnessctl ];
    text = ''
      dim_state_file="''${XDG_RUNTIME_DIR:?}/niri-backlight"
      saved_brightness="$(brightnessctl --class=backlight get)"
      maximum_brightness="$(brightnessctl --class=backlight max)"
      dim_brightness="$((maximum_brightness * ${toString cfg.dim.percentage} / 100))"

      if ((dim_brightness < 1)); then
        dim_brightness=1
      fi

      printf '%s\n' "$saved_brightness" > "$dim_state_file"
      if ((saved_brightness > dim_brightness)); then
        brightnessctl --class=backlight set "$dim_brightness"
      fi
    '';
  };
  restoreBacklight = pkgs.writeShellApplication {
    name = "niri-restore-backlight";
    runtimeInputs = [ pkgs.brightnessctl ];
    text = ''
      dim_state_file="''${XDG_RUNTIME_DIR:?}/niri-backlight"
      if [[ ! -r "$dim_state_file" ]]; then
        exit 0
      fi

      read -r saved_brightness < "$dim_state_file"
      brightnessctl --class=backlight set "$saved_brightness"
      rm -f -- "$dim_state_file"
    '';
  };

  timeouts = lib.optional cfg.dim.enable {
    seconds = cfg.dim.timeout;
    command = lib.getExe dimBacklight;
    resume = lib.getExe restoreBacklight;
  } ++ [
    { seconds = cfg.lockTimeout; command = "swaylock -f"; }
    {
      seconds = cfg.dpmsTimeout;
      command = "niri msg action power-off-monitors";
      resume = "niri msg action power-on-monitors";
    }
  ] ++ lib.optional cfg.sleep.enable {
    seconds = cfg.sleep.timeout;
    command = cfg.sleep.command;
  };

  timeoutArgs =
    lib.concatMapStringsSep " "
      (t:
        "timeout ${toString t.seconds} '${t.command}'"
        + lib.optionalString (t ? resume) " resume '${t.resume}'")
      timeouts;

  swayidleCmd = lib.concatStringsSep " " [
    "${pkgs.swayidle}/bin/swayidle -w"
    timeoutArgs
    "before-sleep 'swaylock -f'"
    "lock 'swaylock -f'"
  ];
in
{
  options.myNixOS.niri.idle = {
    dim = {
      enable = lib.mkEnableOption "dimming the built-in display before locking";

      timeout = lib.mkOption {
        type = lib.types.int;
        default = 240;
        description = "Seconds of idle before dimming the built-in display.";
      };

      percentage = lib.mkOption {
        type = lib.types.ints.between 1 100;
        default = 10;
        description = "Backlight percentage used while the session is dimmed.";
      };
    };

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
      description = "swayidle power manager (dim + lock + DPMS + sleep) for niri";
      wantedBy = [ "niri.service" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      path = [ config.programs.niri.package pkgs.brightnessctl config.myNixOS.swaylock.package ];
      serviceConfig = {
        Type = "simple";
        ExecStart = swayidleCmd;
        ExecStopPost = lib.getExe restoreBacklight;
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
