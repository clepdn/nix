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
				environmentFiles = [
					cfg.envPath
				];
				extraOptions = [
					"--cap-add=NET_ADMIN"
					"--device=/dev/net/tun"
				];
				ports = [ 
					"8888:8888"
					"8388:8388"
					"8000:8000"
				];
			};
		};
	};
}
