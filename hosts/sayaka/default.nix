{ config, pkgs, self, ... }:
{
	imports = [
	      ./disko.nix
	      ./hardware-configuration.nix
	      "${self}/users/callie"
	      "${self}/users/emelia"
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/modules/nginx"
	      "${self}/modules/pds"
	      "${self}/modules/pavement"
	      "${self}/modules/computers.sex"
	];

	myNixOS.nix.homuraBuilder.enable = false;

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

	networking.networkmanager.ensureProfiles.profiles.enp1s0 = {
		connection = {
			id = "enp1s0";
			type = "ethernet";
			"interface-name" = "enp1s0";
		};
		ipv4 = {
			method = "manual";
			address1 = "178.156.177.25/32";
			gateway = "172.31.1.1";
			route1 = "172.31.1.1/32";
			dns = "1.1.1.1;8.8.8.8;";
		};
		ipv6 = {
			method = "manual";
			address1 = "2a01:4ff:f0:deca::1/64,fe80::1";
		};
	};

	boot.loader.grub.enable = true;
	
	networking.firewall.enable = true;
	networking.firewall.allowedTCPPorts = [ 2200 ];
	services.openssh.ports = [ 22 2200 ];

	system.stateVersion = "25.11";
}
