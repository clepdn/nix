{ pkgs, lib, ... }:
{
	services.openssh = {
		enable = true;
		settings = {
			# mkForce: nixos-uconsole's modules/base.nix hardcodes
			# PasswordAuthentication = true and PermitRootLogin = "yes" at normal
			# priority (no mkDefault), so plain values would conflict on clockwork.
			PasswordAuthentication = lib.mkForce false;
			KbdInteractiveAuthentication = false;
			PermitRootLogin = lib.mkForce "no";
		};
	};

	# environment.systemPackages = [ pkgs.tsshd ];
	networking.firewall.allowedUDPPortRanges = [
		{ from = 61001; to = 61999; }
	];
}
