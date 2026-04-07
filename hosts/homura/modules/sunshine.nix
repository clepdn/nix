{ config, pkgs, lib, ... }:
{
  users.users.runner = {
    isNormalUser = true;
    description = "Stream Runner";
    extraGroups = [ "video" "input" "render" "audio" ];
    # Locked password — access is via autologin only
    hashedPassword = "!";
  };

  # inputplumber is a Steam Deck controller remapper — not needed on homura
  services.inputplumber.enable = lib.mkForce false;

  programs.steam.enable = true;

  # Jovian Steam — boots directly into Steam/gamescope on login
  jovian.steam.enable = true;
  jovian.steam.autoStart = true;
  jovian.steam.user = "callie";
  jovian.steam.desktopSession = "plasma"; # fallback DE if Steam exits

  # Plasma as fallback DE when exiting Steam/gamescope
  services.desktopManager.plasma6.enable = true;

  jovian.hardware.has.amd.gpu = false;

  # steamosctl set-default-desktop-session hangs on non-Deck hardware because
  # steamos-manager can't configure its GPU interfaces. As a oneshot service it
  # blocks steam-launcher from ever starting. Give it 10 seconds then move on.
  systemd.user.services.jovian-setup-desktop-session = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStartSec = "10";
  };

  # Sunshine game-streaming server — disabled until gamescope is stable
  services.sunshine = {
    enable = false;
    capSysAdmin = false;
    openFirewall = false;
  };
}
