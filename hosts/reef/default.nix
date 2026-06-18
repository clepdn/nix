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

	age.secrets.slskdEnv = {
		file  = "${self}/secrets/slskd.env.age";
		mode  = "0440";
		owner = "slskd";
		group = "users";
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
				provider        = "deepseek";
				name            = "deepseek-v4-pro";
				enable_thinking = true;
				thinking_effort = "xhigh";
			};
			context.compact_trigger_tokens = 800000;
		};
	};

	services.slskd = {
		enable = true;
		environmentFile = config.age.secrets.slskdEnv.path;
		openFirewall = true;
		settings = {
			shares.directories = [ "/var/lib/slskd/music" ];
			directories.downloads = "/var/lib/slskd/downloads";
			directories.incomplete = "/var/lib/slskd/incomplete";
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

	myNixOS.nix.homuraBuilder.enable = false;

	system.stateVersion = "26.05";
}
