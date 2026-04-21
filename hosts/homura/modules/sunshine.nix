{ config, pkgs, lib, ... }:
{
  users.users.runner = {
    isNormalUser = true;
    description = "Stream Runner";
    extraGroups = [ "video" "input" "render" "audio" ];
    # Locked password — access is via autologin only
    hashedPassword = "$6$D4tCP7GfjkJImwQC$vLV8ROZM3CLi17/m77fPtkrJzKmeXPUp0IFXfseOxIOEuOc5GQUTCe8VoOXHsF1up9NQ/VN/lQhm8diG8bdWo/";
  };

  # inputplumber is a Steam Deck controller remapper — not needed on homura
  services.inputplumber.enable = lib.mkForce false;

  programs.steam.enable = true;

  # Jovian Steam — boots directly into Steam/gamescope on login
  /*
  jovian.steam.enable = true;
  jovian.steam.autoStart = true;
  jovian.steam.user = "callie";
  jovian.steam.desktopSession = "plasma"; # fallback DE if Steam exits
  */

  # Plasma as fallback DE when exiting Steam/gamescope
  services.desktopManager.plasma6.enable = true;

  # SDDM autologin
  services.displayManager.sddm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "runner";
  };
  # Use X11 for better NVIDIA capture compatibility
  services.displayManager.defaultSession = "plasma";

  # jovian.hardware.has.amd.gpu = false;

  # steamosctl set-default-desktop-session hangs on non-Deck hardware because
  # steamos-manager can't configure its GPU interfaces. As a oneshot service it
  # blocks steam-launcher from ever starting. Give it 10 seconds then move on.
  /*
  systemd.user.services.jovian-setup-desktop-session = {
    overrideStrategy = "asDropin";
    serviceConfig.TimeoutStartSec = "10";
  };
  */

  # Sunshine game-streaming server
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    package = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
    };
  };

}
