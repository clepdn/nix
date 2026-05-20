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

		qbittorrent2 = {
			enable = lib.mkEnableOption "second qbittorrent container";
			port = lib.mkOption {
				type = lib.types.int;
				description = "Torrenting port for second qbittorrent instance";
				default = 14821;
			};
			webuiPort = lib.mkOption {
				type = lib.types.int;
				description = "Web UI port for second qbittorrent instance";
				default = 8082;
			};
		};

	};

	config = lib.mkIf cfg.enable (lib.mkMerge [
		{
			virtualisation.podman = {
				enable = true;
				dockerCompat = true;
			};

			virtualisation.oci-containers = {
				backend = "podman";
				containers.gluetun = {
					image = "qmcgaw/gluetun";
					environment = {
						FIREWALL_VPN_INPUT_PORTS = lib.concatStringsSep "," (
							[ (toString cfg.port) ]
							++ lib.optional cfg.qbittorrent2.enable (toString cfg.qbittorrent2.port)
						);
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
						"--cap-add=NET_RAW"
						"--device=/dev/net/tun"
					];
					ports = [
						"1080:1080" # socks
						"8080:8080"
						"${toString cfg.port}:${toString cfg.port}"
						"${toString cfg.port}:${toString cfg.port}/udp"
					] ++ lib.optionals cfg.qbittorrent2.enable [
						"${toString cfg.qbittorrent2.webuiPort}:${toString cfg.qbittorrent2.webuiPort}"
						"${toString cfg.qbittorrent2.port}:${toString cfg.qbittorrent2.port}"
						"${toString cfg.qbittorrent2.port}:${toString cfg.qbittorrent2.port}/udp"
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
		}

		(lib.mkIf cfg.qbittorrent2.enable {
			virtualisation.oci-containers.containers.qbittorrent2 = {
				image = "linuxserver/qbittorrent";
				extraOptions = [
					"--network=container:gluetun"
				];
				environment = {
					TORRENTING_PORT = toString cfg.qbittorrent2.port;
					WEBUI_PORT = toString cfg.qbittorrent2.webuiPort;
					PUID = toString config.users.users.qbit-container.uid;
					PGID = toString config.users.groups.users.gid;
				};
				volumes = [
					"/var/lib/qbit-container2/config:/config"
					"/mnt/hdd/library:/downloads"
				];
				dependsOn = [ "gluetun" ];
			};

			networking.firewall.allowedTCPPorts = [
				cfg.qbittorrent2.webuiPort
				cfg.qbittorrent2.port
			];

			networking.firewall.allowedUDPPorts = [
				cfg.qbittorrent2.port
			];

			systemd.tmpfiles.rules = [
				"d /var/lib/qbit-container2 0755 qbit-container users -"
				"d /var/lib/qbit-container2/config 0755 qbit-container users -"
			];
		})

	]);
}
