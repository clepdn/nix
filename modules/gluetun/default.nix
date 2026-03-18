{ config, pkgs, lib, ... }:

let
	cfg = config.services.gluetun;
in
{
	options.services.gluetun = {
		enable = lib.mkEnableOption "Gluetun container";
		envPath = lib.mkOption {
			type = lib.types.path;
			description = "Path to environment file.";
		};

		port = lib.mkOption {
			type = lib.types.int;
			description = "Port to forward for qbittorrent";
			default = 29955;
		};
	};

	config = lib.mkIf cfg.enable {
		virtualisation.podman = {
			enable = true;
			dockerCompat = true;
		};

		virtualisation.oci-containers = {
			backend = "podman";
			containers.gluetun = {
				image = "qmcgaw/gluetun";
				environment = {
					FIREWALL_VPN_INPUT_PORTS = "${toString cfg.port}";
					SHADOWSOCKS = "on";
					# SHADOWSOCKS_LOG = "on";
					SHADOWSOCKS_CIPHER = "chacha20-ietf-poly1305";
					# SHADOWSOCKS_PASSWORD = down here vvv
				};
				environmentFiles = [
					cfg.envPath
				];
				extraOptions = [
					"--cap-add=NET_ADMIN"
					"--device=/dev/net/tun"
				];
				ports = [ 
					"1080:1080" # socks
					"8080:8080"
					"${toString cfg.port}:${toString cfg.port}"
					"${toString cfg.port}:${toString cfg.port}/udp"
				];
			};

			containers.socks5 = {
				image = "serjs/go-socks5-proxy";
				extraOptions = [
					"--network=container:gluetun"
				];
				dependsOn = [ "gluetun" ];
				environment = {
					REQUIRE_AUTH = "false";
				};
			};

			containers.qbittorrent = {
				image = "linuxserver/qbittorrent";
				extraOptions = [
					"--network=container:gluetun"
				];
				environment = {
					TORRENTING_PORT = toString cfg.port;
					PUID = toString config.users.users.qbit-container.uid;
					PGID = toString config.users.groups.users.gid;
				};
				volumes = [
					"/var/lib/qbit-container/config:/config"
					"/mnt/hdd/library:/downloads"
				];
				dependsOn = [ "gluetun" ];
			};
		};

		users.users.qbit-container = {
			isSystemUser = true;
			group = "users";
		};

	  	networking.firewall.allowedTCPPorts = [
			1080
			8080
			cfg.port
		]; 

	  	networking.firewall.allowedUDPPorts = [
			cfg.port
		]; 

		systemd.tmpfiles.rules = [
			"d /var/lib/qbit-container 0755 qbit-container users -"
			"d /var/lib/qbit-container/config 0755 qbit-container users -"
		];
	};
}
