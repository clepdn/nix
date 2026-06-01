{ config, lib, self, ... }:
{
	boot.isContainer = true;
	users.allowNoPasswordLogin = true;

	users.users.root.openssh.authorizedKeys.keys =
		config.users.users.callie.openssh.authorizedKeys.keys;
	imports = [
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/users/callie"
	];

	networking.hostName = "reef";

	myNixOS.nix.homuraBuilder.enable = false;

	# Containers don't have wifi hardware or need NM
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;

	networking.firewall.enable = true;

	system.stateVersion = "26.05";
}
