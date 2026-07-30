{ config, pkgs, lib, ... }:
let
  cfg = config.myNixOS.swaylock;

  # swaylock only looks at $XDG_CONFIG_HOME/swaylock/config, ~/.swaylock/config
  # and its own compiled-in SYSCONFDIR -- which on Nix is inside the package's
  # store path, not /etc. So a system-wide theme has to be baked in with -C.
  configFile = pkgs.writeText "swaylock-config" ''
    color=1e1e2e
    font=Inter
    font-size=30

    indicator
    indicator-radius=70
    indicator-thickness=8

    clock
    timestr=%-I:%M
    datestr=%A, %B %-d

    inside-color=1e1e2e
    ring-color=f5c2e7
    key-hl-color=9b6dcc
    bs-hl-color=f9e2af
    text-color=f5e0dc
    line-color=00000000
    separator-color=00000000

    inside-clear-color=1e1e2e
    ring-clear-color=f9e2af
    text-clear-color=f9e2af

    inside-ver-color=1e1e2e
    ring-ver-color=b4befe
    text-ver-color=b4befe

    inside-wrong-color=1e1e2e
    ring-wrong-color=f38ba8
    text-wrong-color=f38ba8

    ignore-empty-password
    show-failed-attempts
    indicator-caps-lock
  '';

  themedSwaylock = pkgs.symlinkJoin {
    name = "swaylock-effects-themed";
    paths = [ pkgs.swaylock-effects ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/swaylock --add-flags "-C ${configFile}"
    '';
    meta.mainProgram = "swaylock";
  };
in
{
  options.myNixOS.swaylock = {
    enable = lib.mkEnableOption "the shared swaylock screen locker";

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = themedSwaylock;
      description = ''
        swaylock-effects wrapped so it always loads the shared theme. Use this
        instead of pkgs.swaylock-effects anywhere swaylock is invoked.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    security.pam.services.swaylock.fprintAuth = false;
    environment.systemPackages = [ cfg.package ];
  };
}
