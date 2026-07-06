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

	age.secrets.coralWebhookToken = {
		file  = "${self}/secrets/coral-webhook-token.age";
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

			context = {
				compact_trigger_tokens = 400000;
				idle_compaction_minutes = 0;
				respect_cache = false;
			};

			subagents = [
				{
					name = "explore";
					system_prompt = "You are an exploratory agent. Your goal is to investigate thoroughly to achieve the task assigned to you by your calling agent.";
					enabled_tools = [ "shell" "read_file" ];

				}
				{
					name = "coder";	
					system_prompt = "You are a focused coding agent. Write, edit, and test code. Verify your work compiles.";
					enabled_tools = [ "shell" "read_file" "edit_file" "write_file" ];
				}
			];
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
	myNixOS.nix.signing.enable = true;

	system.stateVersion = "26.05";
}
