# =============================================================================
STOP# ⚠️  STOP. READ THIS BEFORE YOU COPY ANYTHING FROM THIS FILE.  ⚠️
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
				boredom_wake_min = 30;
			};

			models = {
				umans-glm-5_2 = {
					provider         = "openai";
					model            = "umans-glm-5.2";
					base_url         = "https://api.code.umans.ai/v1";
					tool_choice      = "required";
					enable_thinking  = true;
					thinking_effort  = "xhigh";
				};

				umans-kimi = {
					provider         = "openai";
					model            = "umans-kimi-k2.7";
					base_url         = "https://api.code.umans.ai/v1";
					tool_choice      = "required";
					enable_thinking  = true;
					thinking_effort  = "xhigh";
				};

				umans-flash = {
					provider         = "openai";
					model            = "umans-flash";
					base_url         = "https://api.code.umans.ai/v1";
					tool_choice      = "required";
					enable_thinking  = true;
					thinking_effort  = "xhigh";
				};

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
			fallback   = { preset = "umans_kimi";   };
			summary    = { preset = "umans-flash";      };
			embeddings = { preset = "gemini-embedding"; };

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
	
	boot.isNspawnContainer = true;
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;
	networking.firewall.enable = true;
	services.tailscale.enable = lib.mkForce false;

	myNixOS.nix.homuraBuilder.enable = false;
	myNixOS.nix.signing.enable = true;

	system.stateVersion = "26.05";
}
