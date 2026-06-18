{ config, lib, self, pkgs, ... }:
{
	age.secrets.slskdEnv = {
		file  = "${self}/secrets/slskd.env.age";
		mode  = "0440";
		owner = "slskd";
		group = "users";
	};

	systemd.tmpfiles.rules = [
		"d /var/lib/slskd 0770 slskd slskd"
		"d /var/lib/slskd/music 0770 slskd slskd"
		"d /var/lib/slskd/downloads 0770 slskd slskd"
		"d /var/lib/slskd/incomplete 0770 slskd slskd"
	];

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

	networking.firewall.allowedTCPPorts = [ 5030 ];
}
