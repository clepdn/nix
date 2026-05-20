{ config, ... }:
{
	imports = [
		../../../modules/autobrr
	];

	age.secrets.autobrr-session = {
		file = ../../../secrets/autobrr-session.age;
	};

	myNixOS.autobrr = {
		enable = true;
		secretFile = config.age.secrets.autobrr-session.path;
	};
}
