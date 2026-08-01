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

{ config, lib, self, pkgs, ... }:
let basePreset = {
	enable_thinking = true;
	vision = true;
	bridge = true;
	tool_choice = "required";
	deep_archive = true;
	compaction_strategy = "companion";
	journal_before_compaction = true;
};
claudePreset = basePreset // {
	vision = true;
	compact_trigger_tokens = 240000;
	preserve_prompt_cache = true;
};
oaiPreset = claudePreset // {
	compaction_strategy = "remote";
};
gpt-luna  = oaiPreset // {
	model = "gpt-5.6-luna";
	thinking_effort = "xhigh";
};
in
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

			discord.owner_id = "257329343301156886";

			computer_use = {
				enabled = true;
				display = ":99";
			};

			image_tool.max_bytes = 5000000;

			models = {
				umans-glm-5_2 = basePreset // {
					model            = "umans-glm-5.2";
					thinking_effort  = "xhigh";
					vision           = false;
				};

				umans-kimi = basePreset // {
					model            = "umans-kimi-k2.7";
					thinking_effort  = "xhigh";
					vision           = true;
					nudge_on_no_tool = true;
				};

				umans-flash = basePreset // {
					model            = "umans-flash";
					thinking_effort  = "xhigh";
					vision           = true;
					enable_thinking  = true;
					bridge           = true;
					tool_choice      = "required";
				};

				claude = claudePreset // {
					model           = "claude-opus-4-8";
					thinking_effort = "xhigh";
				};

				claude-opus-mid = claudePreset // {
					model           = "claude-opus-4-8";
					thinking_effort = "medium";
				};

				claude-low = claudePreset // {
					model           = "claude-sonnet-5";
					thinking_effort = "medium";
				};

				gpt-luna = gpt-luna;

				gpt-luna-low = oaiPreset // {
					thinking_effort = "low";
				};
				gpt-terra = oaiPreset // {
					model = "gpt-5.6-terra";
					thinking_effort = "high";

				};
				gpt-sol = oaiPreset // {
					model = "gpt-5.6-sol";
					thinking_effort = "high";
				};

				glm-openrouter = {
					provider         = "openrouter";
					model            = "zai-org/glm-5.2";
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

			model      = { preset = "claude";           };
			fallback   = { preset = "gpt-terra";        };
			summary    = { preset = "gpt-luna-low";     };
			embeddings = { preset = "gemini-embedding"; };

			subagents = [
				{
					name = "explore";
					model = "gpt-luna";
					system_prompt = "You are an exploratory agent. Your goal is to investigate thoroughly to achieve the task assigned to you by your calling agent.";
					enabled_tools = [ "shell" "read_file" ];

				}
				{
					name = "coder";
					model = "gpt-luna";
					system_prompt = "You are a focused coding agent. Write, edit, and test code. Verify your work compiles.";
					enabled_tools = [ "shell" "read_file" "edit_file" "write_file" ];
				}
				{
					name = "vision";
					model = "gpt-luna";
					system_prompt = "You are a focused agent with vision.";
					enabled_tools = [ "image_tool" "shell" "read_file" "edit_file" "write_file" ];
				}
				{
					name = "computer";
					model = "gpt-luna";
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
		xvfb
		i3
		i3status
		dmenu
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
	       systemd.services.xvfb = {
               description = "Xvfb Virtual Framebuffer";
               after = [ "multi-user.target" ];
               wantedBy = [ "multi-user.target" ];
               serviceConfig = {
                       ExecStart = "${pkgs.xvfb}/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset";
                       Restart = "always";
                       RestartSec = 3;
               };
       };

       systemd.services.i3 = {
               description = "i3 Window Manager";
               after = [ "xvfb.service" ];
               requires = [ "xvfb.service" ];
               wantedBy = [ "multi-user.target" ];
               serviceConfig = {
                       ExecStart = "${pkgs.i3}/bin/i3 -c /dev/null";
                       Environment = "DISPLAY=:99";
                       User = "coral";
                       Restart = "always";
                       RestartSec = 3;
               };
       };

       # HRT shot reminder — fires daily, but only wakes nano (via the worker
       # webhook) on days that land on callie's injection cadence, so nano DMs her a
       # nudge in her own voice. The schedule is derived deterministically from an
       # anchor shot date + interval, so no mutable state is needed and it
       # self-perpetuates. When callie logs a shot on a different day, bump
       # ANCHOR_DATE. This does NOT depend on nano remembering anything — the date
       # fires it. See memories/people/callie-hrt-shots.md.
       systemd.services.shot-reminder = {
               description = "callie HRT shot reminder";
               serviceConfig = {
                       Type = "oneshot";
                       User = "coral";
                       ExecStart = pkgs.writeShellScript "shot-reminder" ''
                               set -euo pipefail

                               ANCHOR_DATE="2026-07-30"      # a known shot day
                               INTERVAL_DAYS=5               # cadence
                               DOSE="8mg"
                               WORKER_URL="http://127.0.0.1:4221/trigger/webhook"
                               DM_CHANNEL="1509435403143479398"

                               anchor_epoch=$(${pkgs.coreutils}/bin/date -d "$ANCHOR_DATE" +%s)
                               today_epoch=$(${pkgs.coreutils}/bin/date -d "$(${pkgs.coreutils}/bin/date +%F)" +%s)
                               days_since=$(( (today_epoch - anchor_epoch) / 86400 ))

                               if (( days_since < 0 )); then
                                       echo "[shot-reminder] today is before anchor; nothing due"; exit 0
                               fi
                               if (( days_since % INTERVAL_DAYS != 0 )); then
                                       echo "[shot-reminder] not a shot day (days_since=$days_since)"; exit 0
                               fi

                               content="[shot reminder] callie's estradiol shot ($DOSE, every $INTERVAL_DAYS days) is due TODAY ($(${pkgs.coreutils}/bin/date '+%A %B %-d')). DM her a warm nudge in channel $DM_CHANNEL. if she confirms she did it, note the date in her shot log (people/callie-hrt-shots.md)."

                               echo "[shot-reminder] due today (days_since=$days_since); waking nano"
                               ${pkgs.curl}/bin/curl -fsS --max-time 15 -X POST "$WORKER_URL" \
                                       -H 'content-type: application/json' \
                                       -d "$(${pkgs.jq}/bin/jq -nc --arg c "$content" '{content:$c}')"
                       '';
               };
       };

       systemd.timers.shot-reminder = {
               description = "callie HRT shot reminder timer";
               wantedBy = [ "timers.target" ];
               timerConfig = {
                       # 10:00 each day in the service's local time. Services here run in EDT
                       # via the homura /etc/localtime bind-mount (verified: a systemd oneshot
                       # reports -0400), so a bare time is correct. The explicit
                       # "America/New_York" suffix is buggy on this systemd build (it drops the
                       # offset and fires at 06:00 EDT), so don't use it. The script decides if
                       # today actually lands on the shot cadence.
                       OnCalendar = "*-*-* 10:00:00";
                       Persistent = true;   # catch up if the container was down at fire time
               };
       };

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
