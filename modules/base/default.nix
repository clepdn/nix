{ config, pkgs, lib, self, inputs, ... }:
{
	imports = [
		"${self}/modules/ssh/"
		"${self}/modules/nix/"
	];

	environment.systemPackages = with pkgs; [
		jq
		file
		vim
		wget
		kitty # including in base cause pagers freak out when TERM=xterm-kitty
		btop
		mosh # shrug
		wl-clipboard
		mosh
		openssl
		inputs.agenix.packages.${pkgs.system}.default
	];

	programs.git.enable  = true;
	programs.tmux.enable = true;
	programs.fish.enable = true;
	programs.neovim.enable  = true;
	documentation.man.generateCaches = false;
	documentation.man.man-db.enable = false;

	networking.networkmanager.enable = true;
}
