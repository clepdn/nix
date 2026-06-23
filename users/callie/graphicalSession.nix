{ pkgs, lib, ... }:
{
  imports = [
    ./default.nix
  ];

  users.users.callie.packages = with pkgs; [
    spotify
    feishin
    thunderbird
    qdirstat
    kdePackages.kate
    ente-auth
    signal-desktop
    mpv
    pwvucontrol
    pavucontrol

    # niri throttles wl_surface.frame callbacks to 1 Hz for non-visible
    # surfaces, which trips Chromium's renderer-backgrounding heuristics and
    # freezes Discord's window once it loses focus / gets occluded. There is
    # no per-window niri opt-out (see niri-wm/niri discussions #1525, #3494),
    # so disable the Chromium-side backgrounding instead.
    (discord.override {
      withMoonlight = true;
      commandLineArgs = lib.concatStringsSep " " [
        "--disable-renderer-backgrounding"
        "--disable-background-timer-throttling"
        "--disable-backgrounding-occluded-windows"
      ];
    })
  ];
}
