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
#   • The nano executor service, its secrets, and the package set below are tuned for
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

	age.secrets.nanoExecutorToken = {
		file  = "${self}/secrets/nano-executor-token.age";
		mode  = "0400";
		owner = config.services.nano-executor.user;
	};

	services.nano-executor = {
		enable        = true;
		# Her home: cwd, $HOME and relative tool paths all resolve to one
		# place. Migrated from /home/coral (orphaned uid) on 2026-08-06.
		workspace     = "/home/nano";
		listenAddress = "0.0.0.0";
		port          = 4221;
		tokenFile     = config.age.secrets.nanoExecutorToken.path;
		hashline      = true;
		capabilities  = [ "shell" "read_file" "edit_file" "image_tool" "computer" "read_bytes" ];
		imageMaxBytes = 5000000;
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
	users.users.nano.extraGroups = [ "slskd" ];
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
                       User = "nano";
                       Restart = "always";
                       RestartSec = 3;
               };
       };

       systemd.services.shot-reminder = {
               description = "callie HRT shot reminder";
               serviceConfig = {
                       Type = "oneshot";
                       User = "nano";
                       ExecStart = pkgs.writeShellScript "shot-reminder" ''
                               set -euo pipefail

                               ANCHOR_DATE="2026-08-05"      # a known shot day (reset aug 5: missed aug 4, re-anchored)
                               INTERVAL_DAYS=5               # cadence
                               DOSE="8mg"
                               WORKER_URL="http://10.233.1.1:4220/trigger/webhook"   # homura control plane
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
                       OnCalendar = "*-*-* 10:00:00";
                       Persistent = true;
               };
       };

	boot.isNspawnContainer = true;
	networking.networkmanager.enable = lib.mkForce false;
	networking.wireless.enable = false;
	networking.firewall.enable = true;

	# 4221 = executor tool server, reachable only over the private veth.
	networking.firewall.allowedTCPPorts = [ 9100 4221 ];
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
