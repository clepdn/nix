{ self, ... }:
{
	boot.isContainer = true;
	users.allowNoPasswordLogin = true;
	imports = [
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	];

	networking.hostName = "reef";

	myNixOS.nix.homuraBuilder.enable = false;

	networking.firewall.enable = true;

	system.stateVersion = "26.05";
}
