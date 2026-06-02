{ config, lib, self, ... }:
{
	imports = [
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/users/callie"
	];

	networking.hostName = "reef";

	age.secrets.coralEnv = {
		file  = "${self}/secrets/coral.env.age";
		mode  = "0400";
		owner = config.services.coral.user;
	};

	services.coral = {
		enable = true;
		envFile = config.age.secrets.coralEnv.path;
	};

	users.allowNoPasswordLogin = true;
	users.users.root.openssh.authorizedKeys.keys =
		config.users.users.callie.openssh.authorizedKeys.keys;
	
	boot.isNspawnContainer = true;
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;
	networking.firewall.enable = true;

	myNixOS.nix.homuraBuilder.enable = false;

	system.stateVersion = "26.05";
}
