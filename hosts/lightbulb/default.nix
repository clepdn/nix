{ config, pkgs, self, clib, ... }:
{
	imports = clib.importFolder ./modules ++ [
	      ./hardware-configuration.nix
	      "${self}/users/callie"
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	];

	networking.hostName = "lightbulb";
	users.mutableUsers = false;
	myNixOS.nix.homuraBuilder.enable = false;

	networking.firewall.enable = true;

	system.stateVersion = "26.05";
}
