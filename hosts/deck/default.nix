# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, self, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/jovian.nix
      "${self}/users/callie"
      "${self}/modules/tz/ny.nix"
      "${self}/modules/pipewire"
      "${self}/modules/base"
    ];

  services.udisks2.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "deck"; # Define your hostname.

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  # services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.firefox.enable = true;
  environment.systemPackages = with pkgs; [
	(heroic.override {
  		extraPkgs = p: [
	    	pkgs.gamescope
	  	];
	})
  ];

  services.tailscale.enable = true; 
  services.avahi.nssmdns4.enable = true;
  #services.avahi.enable = true; # Don't remember if I need this one.

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.05"; # Did you read the comment?
}
