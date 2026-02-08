{ config, pkgs, lib, ... }:
{	
	imports = [ 
		../../../modules/qbittorrent
	];


	age.secrets.wg-key = {
		file = ../../../secrets/muliphein.age;
		mode = "400";
		owner = "systemd-network";
	};
	age.secrets.wg-pskey = {
		file = ../../../secrets/muliphein-pskey.age;
		mode = "400";
		owner = "systemd-network";
	};
	services.qbit-container = {
		enable = true;
		libraryDir = "/mnt/hdd/library";
		qbitPort = 29955;
		webuiPort = 8080;
		wireguard = {
			presharedKeyFile = config.age.secrets.wg-key.path;
			privateKeyFile = config.age.secrets.wg-pskey.path;
		};
		fwdInterfaceName = "enp6s0";
	};



}
