{ config, pkgs, self, ... }:
{
  imports =
    [ 
      ./hardware-configuration.nix
      ./modules/gluetun.nix
      ./modules/audiobookshelf.nix
      ./modules/minio.nix
      "${self}/users/callie" 
      "${self}/modules/gregtech"
      "${self}/modules/base" 
      "${self}/modules/pipewire" 
      "${self}/modules/tz/ny.nix" 
    ];

  fileSystems."/mnt/hdd" = {
	device = "/dev/disk/by-uuid/eafaf86c-1442-4512-91d2-28c63f79547b";
	fsType = "btrfs";
	options = [ "compress=zstd" ];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homura"; # she graduated

  services.gregtech.enable = true;

  services.xserver.enable = false;

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
     parted
     btrfs-progs
     rclone
     opencode
  ];

  services.tailscale.enable = true;
  services.avahi.nssmdns4.enable = true;

  networking.firewall.enable = true;

  system.stateVersion = "25.11"; # Don't touch me ]: )
}
