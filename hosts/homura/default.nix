{ config, pkgs, self, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/audiobookshelf.nix
      ./modules/jellyfin.nix
      ./modules/gluetun.nix
      ./modules/minio.nix
      ./modules/authelia.nix
      ./modules/home-assistant.nix
      ./modules/wyoming-faster-whisper.nix
      ./modules/wyoming-piper.nix
      #./modules/sunshine.nix
      ./modules/sleepless.nix
      "${self}/users/callie"
      "${self}/modules/comfymc"
      "${self}/modules/base"
      "${self}/modules/pipewire"
      "${self}/modules/monitoring"
      "${self}/modules/tz/ny.nix"
    ];

  fileSystems."/mnt/hdd" = {
	device = "/dev/disk/by-uuid/eafaf86c-1442-4512-91d2-28c63f79547b";
	fsType = "btrfs";
	options = [ "compress=zstd" ];
  };

  hardware.graphics.enable = true;  # was hardware.opengl.enable before NixOS 24.11

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homura"; # she graduated

  users.mutableUsers = false;

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
     parted
     btrfs-progs
     rclone
     opencode
  ];

  services.tailscale.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  networking.firewall.enable = true;

  system.stateVersion = "25.11"; # Don't touch me ]: )
}
