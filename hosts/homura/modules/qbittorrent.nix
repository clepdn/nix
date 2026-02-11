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

	services.gluetun = {
		enable = true;
		envPath = config.age.secrets.gluetun.path;
	};



}
