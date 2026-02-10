{ config, pkgs, lib, ... }:

let
	cfg = config.services.gluetun;
in
{
	options.services.gluetun = {
		enable = lib.mkEnableOption "Gluetun container";
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
				environment = ""
			};
			extraOptions = [
				"--cap-add=NET_ADMIN"
				"--device=/dev/net/tun"
			];
			ports = [ "8888:8888" ];
		};
	};
}
