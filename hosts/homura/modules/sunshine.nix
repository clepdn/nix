{ config, pkgs, ... }:
{
  users.users.runner = {
    isNormalUser = true;
    description = "Stream Runner";
    extraGroups = [ "video" "input" "render" "audio" ];
    # Locked password — access is via autologin only
    hashedPassword = "!";
  };

  # Jovian Steam — boots directly into Steam/gamescope on login
  jovian.steam.enable = true;
  jovian.steam.autoStart = true;
  jovian.steam.user = "runner";
  jovian.steam.desktopSession = "plasma"; # fallback DE if Steam exits

  # Display manager with autologin wired up by jovian.steam
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Sunshine game-streaming server
  services.sunshine = {
    enable = true;
    capSysAdmin = true; # needed for KMS/DRM capture (NVIDIA)
    openFirewall = true;
  };
}
