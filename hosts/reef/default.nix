{ config, lib, self, ... }:
{
	imports = [
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/users/callie"
	];

	networking.hostName = "reef";

	services.coral = {
		enable = true;
		envFile = config.age.secrets.coral-env.path;
	};

	age.secrets.coral-env.file = "${self}/secrets/coral-env.age";

	users.allowNoPasswordLogin = true;

	users.users.root.openssh.authorizedKeys.keys =
		config.users.users.callie.openssh.authorizedKeys.keys;
	
	boot.isContainer = true;
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;
	networking.firewall.enable = true;

	myNixOS.nix.homuraBuilder.enable = false;

	system.stateVersion = "26.05";
}
