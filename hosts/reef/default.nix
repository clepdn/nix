{ config, lib, self, pkgs, ... }:
{
# =============================================================================
# ⚠️  STOP. READ THIS BEFORE YOU COPY ANYTHING FROM THIS FILE.  ⚠️
# -----------------------------------------------------------------------------
# `reef` is a **NixOS nspawn CONTAINER**, not a real host. The configuration
# below is purpose-built for a throwaway container environment and contains
# choices that are DANGEROUS, WRONG, or outright INSECURE on real hardware.
#
# DO NOT mirror, copy, or "take inspiration from" any of the following on a
# real host (i.e. anything else under hosts/):
#
#   • users.allowNoPasswordLogin = true;        ← passwordless root login.
#   • boot.isNspawnContainer = true;            ← nspawn-specific boot config.
#   • networking.networkmanager.enable = mkForce false;
#   • networking.wireless.enable = false;
#   • services.tailscale.enable = mkForce false; ← no mesh networking.
#   • The coral service, its secrets, and the package set below are tuned for
#     this container's workload, not a general-purpose system.
#
# If you find yourself reaching for something in here while configuring a real
# host, STOP. It almost certainly does not apply. Write the real config from
# scratch using the other hosts/ as reference instead.
# =============================================================================
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

	age.secrets.bridgetClientKey = {
		file  = "${self}/secrets/bridget-client-key.age";
		mode  = "0400";
		owner = config.services.coral.user;
	};

	services.coral = {
		enable      = true;
		secretsFile = config.age.secrets.coralSecrets.path;

		agents.coral = {
			client = "local";
			home   = "/home/coral";
		};

		settings = {
			server.port = 4220;
			agent = {
				name = "coral";
				env  = "default";
				boredom_wake_min = 0;
				git_upstream_nag = true;
			};

			llm_bridge_url = "https://bridget.on-her.computer/v1";
			llm_bridge_api_key_file = config.age.secrets.bridgetClientKey.path;

			tools.hashline = true;

			discord.owner_id = "1509338575131512974";

			context = {
				compact_trigger_tokens = 400000;
				idle_compaction_minutes = 0;
				respect_cache = false;
			};

			models = {
				umans-glm-5_2 = {
					model            = "umans-glm-5.2";
					thinking_effort  = "xhigh";
					enable_thinking  = true;
					bridge           = true;
					vision           = false;
					tool_choice      = "required";
				};

				umans-kimi = {
					model            = "umans-kimi-k2.7";
					thinking_effort  = "xhigh";
					enable_thinking  = true;
					vision           = true;
					bridge           = true;
					tool_choice      = "required";
				};

				umans-flash = {
					model            = "umans-flash";
					thinking_effort  = "xhigh";
					enable_thinking  = true;
					bridge           = true;
					tool_choice      = "required";
				};

				/*claude = {
					model           = "claude-opus-4-8";
					thinking_effort = "xhigh";
					enable_thinking = true;
					vision          = true;
					bridge          = true;
					tool_choice     = "required";
				};*/

				# If we're budgeting, why the fuck are we even using claude? Just use umans, or openrouter glm?
				/*claude-mid = {
					model           = "claude-opus-4-8";
					thinking_effort = "medium";
					enable_thinking = true;
					vision          = true;
					bridge          = true;
					tool_choice     = "required";
				};*/

				/*claude-low = {
					model           = "claude-sonnet-5";
					thinking_effort = "medium";
					enable_thinking = true;
					vision          = true;
					bridge          = true;
					tool_choice     = "required";
				};*/

				glm-openrouter = {
					provider         = "openrouter";
					model            = "zai-org/glm-4.7-flash";
					tool_choice      = "required";
					thinking_effort  = "xhigh";
				};

				gemini-embedding = {
					provider   = "openai";
					model      = "google/gemini-embedding-2-preview";
					base_url   = "https://openrouter.ai/api/v1";
					dimensions = 3072;
				};
			};

			model      = { preset = "umans-glm-5_2";    };
			fallback   = { preset = "umans-kimi";       };
			summary    = { preset = "umans-flash";      };
			embeddings = { preset = "gemini-embedding"; };

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
				{
					name = "vision";
					model = "umans-kimi";
					system_prompt = "You are a focused agent with vision.";
					enabled_tools = [ "image_tool" "shell" "read_file" "edit_file" "write_file" ];
				}
				{
					name = "computer";
					model = "umans-kimi";
					system_prompt = "You are a computer use agent. You can take screenshots, click, type, scroll, and drag on a graphical desktop. Always screenshot first to see the current state before acting. Work step by step: observe, act, observe again.";
					enabled_tools = [ "computer" "image_tool" "shell" "read_file" "edit_file" "write_file" ];
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
		(python3.withPackages (ps: with ps; [
			spacy
			numpy
			textstat
			transformers
			torch
		]))
	];

	users.allowNoPasswordLogin = true;
	users.users.root.openssh.authorizedKeys.keys =
		config.users.users.callie.openssh.authorizedKeys.keys;

	users.groups.slskd.gid = 962;
	users.users.coral.extraGroups = [ "slskd" ];
	
	boot.isNspawnContainer = true;
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;
	networking.firewall.enable = true;
	# Expose the coral prometheus exporter to homura (the container host) so its
	# prometheus can scrape it. The only non-loopback interface is the veth to
	# homura, so 9100 is not reachable beyond the host.
	networking.firewall.allowedTCPPorts = [ 9100 ];
	services.tailscale.enable = lib.mkForce false;

	myNixOS.nix.homuraBuilder.enable = false;
	myNixOS.nix.signing.enable = true;

	# Allow container to rebuild itself from inside with `nixos-rebuild`
	nix.settings.store = "daemon";
	systemd.sockets.nix-daemon.enable = false;
	systemd.services.nix-daemon.enable = false;
	nix.gc.automatic = lib.mkForce false;
	nix.optimise.automatic = lib.mkForce false;

	# nspawn bind-mounts homura's zoneinfo over /etc/localtime, so setup-etc can't
	# replace it and warns on every switch. Both sides are America/New_York.
	environment.etc."localtime".enable = false;

	system.stateVersion = "26.05";
}
