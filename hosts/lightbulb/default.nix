{ config, pkgs, self, clib, ... }:
{
	imports = clib.importFolder ./modules ++ [
	      ./hardware-configuration.nix
	      "${self}/users/callie"
	      "${self}/modules/base"
	      "${self}/modules/avahi"
	      "${self}/modules/tz/ny.nix"
	      "${self}/modules/podman"
	];

	networking.hostName = "lightbulb";
	users.mutableUsers = false;
	myNixOS.nix.homuraBuilder.enable = false;
	myNixOS.podman.enable = true;

	networking.firewall.enable = true;

	system.stateVersion = "26.05";
}
