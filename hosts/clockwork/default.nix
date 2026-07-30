{ lib, self, pkgs, pkgsUnstable, ... }:
let
	statusScript = pkgs.writeShellScript "sway-status" ''
		while true; do
			bat=$(cat /sys/class/power_supply/*/capacity 2>/dev/null | head -n1)
			stat=$(cat /sys/class/power_supply/*/status 2>/dev/null | head -n1)
			echo "''${stat} ''${bat}%  |  $(date '+%a %d %b  %H:%M')"
			sleep 10
		done
	'';
in
{
	imports = [
		"${self}/modules/sway"
		"${self}/users/callie/account.nix"
		"${self}/users/emelia"
		"${self}/modules/base"
		"${self}/modules/tz/ny.nix"
	];

	myNixOS.sway = {
		enable = true;
		modifier = "Mod1";
		statusCommand = "${statusScript}";
		outputConfig = ''
			### Display (built-in uConsole panel)
			# Kernel revisions expose the portrait DSI panel under either name.
			output DSI-1 {
				mode 720x1280
				transform 90
				scale 1.0
			}
			output DSI-2 {
				mode 720x1280
				transform 90
				scale 1.0
			}
			output HDMI-A-1 {
				scale 1.0
				position 1280 0
			}
		'';
	};

	environment.systemPackages = with pkgsUnstable; [
		firefox
		pavucontrol
		(lib.hiPrio foot)
		htop
	];

	networking.hostName = "clockwork";
	networking.firewall.enable = true;

	services.tailscale.enable = true;

	time.timeZone = "America/New_York";

	# --- Battery / performance notes -------------------------------------------
	# nixos-uconsole ships an aggressive, always-turbo config.txt (arm_freq=2000,
	# over_voltage=6, force_turbo=1) which is great for speed but drains the
	# battery. To trade some performance for runtime, uncomment:

	hardware.raspberry-pi.config.cm4.options.force_turbo.value = "0";
	hardware.raspberry-pi.config.cm4.options.arm_freq.value    = "1500";
	hardware.raspberry-pi.config.cm4.options.over_voltage.value = "2";

	# Generating every man-db cache under aarch64 emulation takes hours.
	documentation.man.generateCaches = lib.mkForce false;

	system.stateVersion = lib.mkDefault "25.11";
}
