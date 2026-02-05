{ config, pkgs, lib, ... }:

let 
	cfg = config.services.qbit-container;
in
{
	options.services.qbit-container = {
		enable = lib.mkEnableOption "qBittorrent Container";

		libraryDir = lib.mkOption {
			type = lib.types.path;
			description = "Shared container library path";
		};

			type = lib.types.str;
	};

	config = lib.mkIf cfg.enable {
	};
}
