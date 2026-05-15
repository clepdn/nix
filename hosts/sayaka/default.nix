{ config, pkgs, self, ... }:
{
	imports = [
	      ./disko.nix
	      ./hardware-configuration.nix
	      "${self}/users/callie"
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/modules/nginx"
	      "${self}/modules/pavement"
	      "${self}/modules/pds"
	      "${self}/modules/nix/homura-builder.nix"
	];

	myNixOS.nix.homuraBuilder.enable = true;

	myNixOS.pavement = {
		enable = true;
		port = 3400;
	};

	myNixOS.pds = {
		enable = true;
		hostname = "pds2.on-her.computer";
		port = 3084;
		secretFile = "${self}/secrets/pds.env.age";
	};

	networking.hostName = "sayaka";
	users.mutableUsers = false;

	boot.loader.grub = {
		enable = true;
	};
	
	services.tailscale.enable  = true;
	networking.firewall.enable = true;

	system.stateVersion = "25.11";
}
