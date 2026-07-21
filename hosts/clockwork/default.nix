{ lib, self, ... }:
{
	imports = [
		./modules/sway.nix
		"${self}/users/callie/account.nix"
		"${self}/users/emelia"
		"${self}/modules/base"
		"${self}/modules/tz/ny.nix"
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

	system.stateVersion = lib.mkDefault "25.11";
}
