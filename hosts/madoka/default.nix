{ config, pkgs, lib, inputs, self, clib, mypkgs, ... }:

{
  imports = clib.importFolder ./modules ++ [
      ./hardware-configuration.nix
      "${self}/users/callie/graphicalSession.nix"
      "${self}/modules/base"
      "${self}/modules/pipewire"
      "${self}/modules/easyeffects"
      "${self}/modules/plymouth"
      "${self}/modules/altserver"
      "${self}/modules/doh"
      "${self}/modules/avahi"
      "${self}/modules/steam"
      "${self}/modules/tools"
      "${self}/modules/tz/ny.nix"
      "${self}/modules/nix-ld/steam-run.nix"
      "${self}/modules/nix-ld/slippi.nix"
      "${self}/modules/nix-ld/mcef.nix"
      "${self}/modules/nix-ld/iloader.nix"
      "${self}/modules/podman"
      "${self}/modules/paseo"
    ];

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "callie" ];

  networking.hostName = "madoka"; # Define your hostname.
  myNixOS.nix.signing.enable = true;

  security.tpm2.enable = true;

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "resume_offset=20391936" "kernel.nmi_watchdog=0" "i2c_hid_acpi.polling_mode=1" ];
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

  # aarch64 emulation (qemu-user via binfmt) so madoka can build/deploy the
  # clockwork (uConsole) system without offloading to the CM4.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Trust the same binary caches clockwork uses, otherwise madoka would try to
  # recompile the patched aarch64 kernel + Raspberry Pi stack from source under
  # qemu (slow, and some of those builds can't be sandboxed under emulation).
  # With these, the heavy artifacts are fetched prebuilt and only trivial
  # per-host drvs are actually built.
  nix.settings = {
    extra-substituters = [
      "https://nixos-clockworkpi-uconsole.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-clockworkpi-uconsole.cachix.org-1:6NRN3n9/r3w5ZS8/gZudW6PkPDoC3liCt/dBseICua0="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };

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

  services.xserver.enable = true;
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

  # This is a hack. Just convert pkgs.nix to a normal file sob. And then agenix can just... go in there like normal. lol.
  environment.systemPackages = with pkgs;
  	import ./pkgs.nix { inherit pkgs mypkgs; }
	++ [ inputs.agenix.packages.${pkgs.system}.default ];
  	/*(with pkgs; import ./pkgs.nix { inherit pkgs; })
  	++ [ inputs.agenix.packages.${system}.default ];*/

  programs.firefox.enable = true;

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

  services.logind = {
  	settings.Login = {
		HandleLidSwitch = "suspend-then-hibernate";
		HandleLidSwitchExternalPower = "suspend-then-hibernate";
		HandleLidSwitchDocked = "suspend-then-hibernate";
	};
  };


  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "8h";
  };

  services.fprintd.enable  = true;
  services.printing.enable = true; # CUPS

  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

  # Keep the i2c_designware controller awake so the Synaptics touchpad
  # (VEN_06CB on i2c_designware.2) can initialise without timing out.
  services.udev.extraRules = ''
    SUBSYSTEM=="platform", DRIVER=="i2c_designware", ATTR{power/control}="on"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0955", MODE="0664", GROUP="plugdev"
  '';

  users.groups.plugdev = {};

services.tlp.settings={
    # plugged in
    CPU_BOOST_ON_AC  = 1;
    CPU_MAX_PERF_ON_AC = 100;
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";

    PCIE_ASPM_ON_AC = "performance";
    WIFI_PWR_ON_AC = "off";

    PLATFORM_PROFILE_ON_AC = "balanced";

    # battery
    CPU_BOOST_ON_BAT = 1;
    CPU_MAX_PERF_ON_BAT = 80;
    CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
    
    PCIE_ASPM_ON_BAT = "powersave";
    WIFI_PWR_ON_BAT = "off";
    
    PLATFORM_PROFILE_ON_BAT = "power";

    # power-save

    CPU_BOOST_ON_SAV = 0;
    CPU_MAX_PERF_ON_SAV = 60;
    CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

    PCIE_ASPM_ON_SAV = "powersupersave";
    WIFI_PWR_ON_SAV  = "on";

    PLATFORM_PROFILE_ON_SAV = "quiet";
  };

  services.flatpak.enable = true;

  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
  myNixOS.podman.enable = true;
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  system.stateVersion = "25.11"; # Don't change me : )


}
