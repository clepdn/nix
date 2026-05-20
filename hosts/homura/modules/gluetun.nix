{ config, pkgs, lib, ... }:
{	
	imports = [ 
		../../../modules/gluetun
	];

	age.secrets.gluetun = {
		file = ../../../secrets/gluetun.age;
		mode = "400";
		owner = "systemd-network";
	};

	users.groups.library-extra = {};
	users.users.qbit-container.extraGroups = [ "library-extra" ];

	services.gluetun = {
		enable = true;
		envPath = config.age.secrets.gluetun.path;
		qbittorrent2.enable = true;
	};
}
