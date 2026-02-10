{ config, pkgs, lib, ... }:
{
	services.audiobookshelf = {
		enable = true;
		port = 6969;
		host = "0.0.0.0";
		openFirewall = true;
	};
}
