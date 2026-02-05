# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, inputs, system, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  hardware.nvidia.open = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.tpm2.enable = true;

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.kernelModules = [ "bbswitch" ];
  boot.blacklistedKernelModules = [ 
  	"nouveau"
	"nvidia"
  ];
  boot.kernelParams = [ "resume_offset=13154304" "kernel.nmi_watchdog=0" ];
  boot.resumeDevice = "/dev/disk/by-uuid/ecd7de27-4f77-43e6-b739-6a1152933f98";

  boot.extraModprobeConfig = ''
	options bbswitch load_state=0 unload_state=1	
  '';

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
  	config.boot.kernelPackages.bbswitch
	config.boot.kernelPackages.xpadneo
	config.boot.kernelPackages.nvidiaPackages.stable
  ];

  swapDevices = [{
  	device = "/var/lib/swapfile";
	size = 32*1024;
  }];

  powerManagement.enable = true;

  networking.hostName = "xps"; # Define your hostname.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  #security.pam.services.sddm.fprintAuth = false;
  security.pam.services.login = {
	rules.auth.fprintd = lib.mkForce { enable = false; };
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
     alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.callie = {
    isNormalUser = true;
    description = "Callie";
    extraGroups = [ "networkmanager" "wheel" "input" "video" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
      inputs.zen-browser.packages."${pkgs.system}".default
      qdirstat
      feishin
      thunderbird
    ];
  };

  nixpkgs.config.allowUnfree = true;

  # Programs

  environment.systemPackages = with pkgs;
  	import ./pkgs.nix { inherit pkgs; }
	++ [ inputs.agenix.packages.${pkgs.system}.default ];
  	/*(with pkgs; import ./pkgs.nix { inherit pkgs; })
  	++ [ inputs.agenix.packages.${system}.default ];*/

  programs.firefox.enable     	 = true;
  programs.neovim.enable      	 = true;
  programs.git.enable         	 = true;
  programs.tmux.enable        	 = true;
  programs.fish.enable        	 = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget

  fonts.packages = with pkgs; [
	noto-fonts-cjk-sans
	maple-mono.variable
	inputs.apple-color-emoji.packages."${pkgs.system}".default
  ];
  fonts.fontconfig.defaultFonts.emoji = [ "Apple Color Emoji" ];

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

  services.openssh = {
	enable = true;
	settings = {
	PasswordAuthentication = false;
		KbdInteractiveAuthentication = false;
		PermitRootLogin = "no"; # Maybe prohibit-password for nix build. dunno. not gonna be building shit on my laptop.
	};
  };

  # services.avahi.nssmdns4.enable = true; # I don't particularly need this to be enabled on my (portable) laptop.
  services.tailscale.enable = true;
  services.resolved.enable = true;
  networking.networkmanager.enable = true;

  services.fprintd.enable  = true;
  services.printing.enable = true; # CUPS
  # no relation

  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

  services.flatpak.enable = true;

  hardware.bluetooth = {
	enable = true;
	powerOnBoot = true;
	settings = {
		General = {
			# Show battery charge of connected devices.
			Experimental = true;
			# Faster connections. Uses more power.
			FastConnectable = false;
		};
		Policy = {
			AutoEnable = true;
		};
	};
  };

  virtualisation.waydroid.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
