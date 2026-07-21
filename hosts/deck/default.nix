{ pkgs, self, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/jovian.nix
      "${self}/users/callie/graphicalSession.nix"
      "${self}/modules/tz/ny.nix"
      "${self}/modules/pipewire"
      "${self}/modules/easyeffects"
      "${self}/modules/base"
    ];

  networking.hostName = "deck"; 

  services.udisks2.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.steam-hardware.enable = true;

  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = true;

  programs.firefox.enable = true;
  environment.systemPackages = with pkgs; [
	(heroic.override {
  		extraPkgs = p: [
	    	pkgs.gamescope
	  	];
	})

	prismlauncher
  ];

  # Deck has no agenix key enrolled yet — opt out until it does.
  myNixOS.nix.homuraBuilder.enable = false;

  services.tailscale.enable = true;
  services.avahi.nssmdns4.enable = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
