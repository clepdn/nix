{ config, lib, self, pkgs, ... }:
{
	imports = [
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/users/callie"
	];

	networking.hostName = "reef";

	age.secrets.coralSecrets = {
		file  = "${self}/secrets/coral-secrets.toml.age";
		mode  = "0400";
		owner = config.services.coral.user;
	};

	services.coral = {
		enable      = true;
		secretsFile = config.age.secrets.coralSecrets.path;
		settings = {
			server.port = 4220;
			agent = {
				name = "coral";
				env  = "default";
			};
			model = {
				name            = "umans-glm-5.2";
				base_url        = "https://api.code.umans.ai/v1";
				enable_thinking = true;
				thinking_effort = "xhigh";
			};
			context.compact_trigger_tokens = 400000;
			context.idle_compaction_minutes = 45;
		};
	};

	environment.systemPackages = with pkgs; [
		nodejs_22
		python3
		gcc
		gnumake
		pkg-config
	];

	users.allowNoPasswordLogin = true;
	users.users.root.openssh.authorizedKeys.keys =
		config.users.users.callie.openssh.authorizedKeys.keys;
	
	boot.isNspawnContainer = true;
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;
	networking.firewall.enable = true;
	services.tailscale.enable = lib.mkForce false;

	myNixOS.nix.homuraBuilder.enable = false;

	system.stateVersion = "26.05";
}
