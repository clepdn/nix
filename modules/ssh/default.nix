{ config, pkgs, lib, ... }:
{
	services.openssh = {
		enable = true;
		settings = {
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = "no"; 
		};
	};

	# tsshd: UDP-based SSH server with mosh-like roaming.
	# Spawned per-session by `tssh --udp` after a normal OpenSSH login;
	# reuses /etc/ssh/sshd_config so no extra config needed. Just needs to
	# be on PATH and the default UDP port range open.
	environment.systemPackages = [ pkgs.tsshd ];
	networking.firewall.allowedUDPPortRanges = [
		{ from = 61001; to = 61999; }
	];
}
