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

	# Hetzner Cloud assigns the /64 to the host; no RA accepted by default,
	# so configure the address statically. Gateway is the link-local on the
	# Hetzner switch (fe80::1).
	networking.interfaces.enp1s0.ipv6.addresses = [
		{ address = "2a01:4ff:f0:deca::1"; prefixLength = 64; }
	];
	networking.defaultGateway6 = {
		address = "fe80::1";
		interface = "enp1s0";
	};

	boot.loader.grub = {
		enable = true;
	};
	
	networking.firewall.enable = true;

	system.stateVersion = "25.11";
}
