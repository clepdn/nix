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
					SHADOWSOCKS = "on";
					SHADOWSOCKS_LOG = "on";
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
				];
			};

			containers.socks5 = {
				image = "serjs/go-socks5-proxy";
				environment = {
					REQUIRE_AUTH = "false";
				};
				extraOptions = [
					"--network=container:gluetun"
				];
				dependsOn = [ "gluetun" ];
			};
		};

	  	networking.firewall.allowedTCPPorts = [
			1080
		]; 
	};
}
