# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, system, self, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/bluetooth.nix
      ./modules/nvidia.nix
      "${self}/users/callie" 
      "${self}/modules/base" 
      "${self}/modules/pipewire" 
      "${self}/modules/tz/ny.nix" 
    ];


  networking.hostName = "xps"; # Define your hostname.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.tpm2.enable = true;

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "resume_offset=13154304" "kernel.nmi_watchdog=0" ];
  boot.resumeDevice = "/dev/disk/by-uuid/ecd7de27-4f77-43e6-b739-6a1152933f98";

  boot.initrd.luks.devices."luks-60eb24d2-61d5-4f6e-9912-0534a366e72c" = {
	# device = "/dev/disk/by-uuid/60eb24d2-61d5-4f6e-9912-0534a366e72c";
	# ^ defined in hardware-configuration.nix
	crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
	enable = true;
	pkiBundle = "/var/lib/sbctl";
  };

  boot.extraModulePackages = [ 
	config.boot.kernelPackages.xpadneo
  ];

  swapDevices = [{
  	device = "/var/lib/swapfile";
	size = 64*1024;
  }];

  fileSystems."/".options = [ "noatime" ];
  fileSystems."/home".options = [ "relatime" ];

  powerManagement.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  
  # SDDM does not display that it's waiting for a fingerprint. Disable it entirely.
  security.pam.services.login = {
	rules.auth.fprintd = lib.mkForce { enable = false; };
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # and wayland :ujel:
  # services.xserver.libinput.enable = true;

  # Programs

  environment.systemPackages = with pkgs;
  	import ./pkgs.nix { inherit pkgs; }
	++ [ inputs.agenix.packages.${pkgs.system}.default ];
  	/*(with pkgs; import ./pkgs.nix { inherit pkgs; })
  	++ [ inputs.agenix.packages.${system}.default ];*/

  programs.firefox.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  fonts.packages = with pkgs; [
	noto-fonts-cjk-sans
	maple-mono.variable
        # inputs.apple-color-emoji.packages."${pkgs.system}".default
  ];
  # fonts.fontconfig.defaultFonts.emoji = [ "Apple Color Emoji" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.logind = {
  	settings.Login = {
		HandleLidSwitch = "suspend";
	};
  };

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=4h
  '';

  # services.avahi.nssmdns4.enable = true; # I don't particularly need this to be enabled on my (portable) laptop.
  services.tailscale.enable = true;
  services.resolved.enable = true;

  # no relation
  services.fprintd.enable  = true;
  services.printing.enable = true; # CUPS

  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

  services.flatpak.enable = true;

  virtualisation.waydroid.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.11"; # Don't change me : )

}
