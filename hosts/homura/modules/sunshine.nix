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

  # Jovian Steam — boots directly into Steam/gamescope on login
  jovian.steam.enable = true;
  jovian.steam.autoStart = true;
  jovian.steam.user = "runner";
  jovian.steam.desktopSession = "plasma"; # fallback DE if Steam exits

  # Plasma as fallback DE when exiting Steam/gamescope
  services.desktopManager.plasma6.enable = true;

  # Sunshine game-streaming server
  services.sunshine = {
    enable = true;
    capSysAdmin = true; # needed for KMS/DRM capture (NVIDIA)
    openFirewall = true;
  };
}
