{ config, pkgs, self, clib, ... }:
{
  imports = clib.importFolder ./modules ++ [
      ./hardware-configuration.nix
      "${self}/users/callie/graphicalSession.nix"
      "${self}/modules/base"
      "${self}/modules/avahi"
      "${self}/modules/pipewire"
      "${self}/modules/tools"
      "${self}/modules/monitoring"
      "${self}/modules/tz/ny.nix"
      "${self}/modules/open-webui"
      "${self}/modules/podman"
      
    ];

  # Bootloader.
  boot = {
    initrd.systemd.enable = true;
    enableContainers = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  # Homura is the build server — don't offload back to itself.
  myNixOS.nix.homuraBuilder.enable = false;
  myNixOS.nix.signing.enable = true;
  myNixOS.podman.enable = true;

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

  networking = {
    firewall.enable = true;
    firewall.trustedInterfaces = [ "podman+" ];
    firewall.extraCommands = ''
      iptables -A FORWARD -i podman+ -j ACCEPT
      iptables -A FORWARD -o podman+ -j ACCEPT
    '';
    firewall.extraStopCommands = ''
      iptables -D FORWARD -i podman+ -j ACCEPT || true
      iptables -D FORWARD -o podman+ -j ACCEPT || true
    '';

    # NAT for nixos-container instances (ve-* interfaces)
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "enp6s0";
    };
  };

  system.stateVersion = "25.11"; # Don't touch me ]: )

}
