{ config, lib, self, pkgs, ... }:
{
	age.secrets.slskdEnv = {
		file  = "${self}/secrets/slskd.env.age";
		mode  = "0440";
		owner = "slskd";
		group = "users";
	};

	services.slskd = {
		enable = true;
		environmentFile = config.age.secrets.slskdEnv.path;
		openFirewall = true;
		settings = {
			shares.directories = [ "/var/lib/slskd/music" ];
			directories.downloads = "/var/lib/slskd/downloads";
			directories.incomplete = "/var/lib/slskd/incomplete";
		};
	};
}
