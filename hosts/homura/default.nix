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
      #./modules/wyoming-parakeet.nix
      ./modules/wyoming-faster-whisper.nix
      ./modules/wyoming-piper.nix
      ./modules/sunshine.nix
      ./modules/sleepless.nix
      ./modules/slugtan.nix
      "${self}/users/callie"
      "${self}/modules/comfymc"
      "${self}/modules/base"
      "${self}/modules/pipewire"
      "${self}/modules/monitoring"
      "${self}/modules/tz/ny.nix"
    ];

  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    hostKeys = [ "/etc/secrets/initrd/ssh_host_initrd_key" ];
    authorizedKeys = config.users.users.callie.openssh.authorizedKeys.keys;
  };

  boot.initrd.luks.devices."hdd" = {
    device = "/dev/disk/by-uuid/f43fb5e6-2a5e-42a8-b0d0-fe43f495ad33";
  };

  fileSystems."/mnt/hdd" = {
    device = "/dev/mapper/hdd";
    fsType = "btrfs";
    options = [ "compress=zstd" ];
  };

  swapDevices = [{
  	device = "/var/lib/swapfile";
	size = 64*1024;
  }];

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
  #services.displayManager.sddm.enable = true;
  #services.desktopManager.plasma6.enable = true;

  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
     parted
     btrfs-progs
     rclone
     opencode
     pi-coding-agent
  ];

  services.tailscale.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  networking.firewall.enable = true;

  system.stateVersion = "25.11"; # Don't touch me ]: )
}
