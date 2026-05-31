{ self, ... }:
{
	imports = [
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	];

	networking.hostName = "reef";

	networking.firewall.enable = true;

	system.stateVersion = "26.05";
}
