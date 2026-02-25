{ config, pkgs, self, ... }:
{
	imports = [
	      ./hardware-configuration.nix
	      "${self}/users/callie" 
	      "${self}/modules/base" 
	      "${self}/modules/tz/ny.nix" 
	];

	networking.hostName = "hetzner";
	users.mutableUsers = false;
	
	services.tailscale.enable  = true;
	networking.firewall.enable = true;

	system.stateVersion = 25.11;
}
