{ config, pkgs, self, clib, ... }:
{
  imports = clib.importFolder ./modules ++ [
      ./hardware-configuration.nix
      "${self}/modules/llama-cpp"
      "${self}/modules/letta"
      "${self}/users/callie/graphicalSession.nix"
      "${self}/modules/comfymc"
      "${self}/modules/base"
      "${self}/modules/pipewire"
      "${self}/modules/monitoring"
      "${self}/modules/ttyd"
      "${self}/modules/tz/ny.nix"
    ];

  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices."hdd" = {
    device = "/dev/disk/by-uuid/f43fb5e6-2a5e-42a8-b0d0-fe43f495ad33";
  };

  fileSystems."/mnt/hdd" = {
    device = "/dev/mapper/hdd";
    fsType = "btrfs";
    options = [ "compress=zstd" "nofail" ];
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

  # Homura is the build server — don't offload back to itself.
  myNixOS.nix.homuraBuilder.enable = false;

  # Accept remote build connections from other machines.
  users.users.nix-remote-builder = {
    isSystemUser = true;
    group = "nix-remote-builder";
    # nologin — this account exists only for `nix-daemon --stdio` over SSH,
    # invoked by the remote-builder machinery. It should never be interactive.
    shell = pkgs.shadow;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5jL+9rDxsmB6Kdj1nTykQ7wma71EsilUXWPTqHybi4 nix-remote-builder"
    ];
  };
  users.groups.nix-remote-builder = {};
  nix.settings.trusted-users = [ "nix-remote-builder" ];

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

  services.avahi.enable = true;
  services.avahi.nssmdns4 = true;

  networking.firewall.enable = true;
  networking.firewall.trustedInterfaces = [ "podman+" ];
  networking.firewall.extraCommands = ''
    iptables -A FORWARD -i podman+ -j ACCEPT
    iptables -A FORWARD -o podman+ -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D FORWARD -i podman+ -j ACCEPT || true
    iptables -D FORWARD -o podman+ -j ACCEPT || true
  '';

  # NAT for nixos-container instances (ve-* interfaces)
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "enp6s0";
  };

  system.stateVersion = "25.11"; # Don't touch me ]: )
}
