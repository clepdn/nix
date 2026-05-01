{ config, pkgs, self, clib, ... }:
{
  imports = clib.importFolder ./modules ++ [
      ./hardware-configuration.nix
      "${self}/modules/llama-cpp"
      "${self}/modules/letta"
      "${self}/users/callie"
      "${self}/modules/comfymc"
      "${self}/modules/base"
      "${self}/modules/pipewire"
      "${self}/modules/monitoring"
      "${self}/modules/ttyd"
      "${self}/modules/tz/ny.nix"
    ];

  boot.initrd.network.enable = true;
  # Static IP for initrd SSH so LUKS password can be entered remotely.
  # Connect to 192.168.1.10:2222 before the machine finishes booting.
  boot.kernelParams = [ "ip=192.168.1.10::192.168.1.1:255.255.255.0:homura::none" ];
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
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
     claude-code
  ];

  myNixOS.ttyd = {
    enable = true;
    port = 7681;
  };

  services.tailscale.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  networking.firewall.enable = true;

  # dbus-broker transition requires a reboot; keep old daemon until then
  services.dbus.implementation = "dbus";

  system.stateVersion = "25.11"; # Don't touch me ]: )
}
