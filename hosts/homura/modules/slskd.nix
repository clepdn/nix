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

	# Pin slskd's gid. The coral container recreates this exact gid to reach the
	# bind-mounted /var/lib/slskd across the privateUsers=no boundary, so it must
	# not drift from the dynamic allocation. Keep this in sync with
	# hosts/reef/default.nix (users.groups.slskd.gid).
	users.groups.slskd.gid = 962;

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
