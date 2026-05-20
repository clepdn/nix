{ config, lib, pkgs, ... }:
let
	cfg = config.myNixOS.autobrr;
in {
	options.myNixOS.autobrr = {
		enable = lib.mkEnableOption "autobrr download automation";

		secretFile = lib.mkOption {
			type = lib.types.path;
			description = "Path to file containing the session secret.";
		};

		port = lib.mkOption {
			type = lib.types.port;
			default = 7474;
			description = "Port for autobrr to listen on.";
		};
	};

	config = lib.mkIf cfg.enable {
		services.autobrr = {
			enable = true;
			openFirewall = true;
			secretFile = cfg.secretFile;
			settings = {
				host = "0.0.0.0";
				port = cfg.port;
			};
		};
	};
}
