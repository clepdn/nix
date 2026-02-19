{ config, pkgs, lib, self, ... }:
{
	imports = [
		"${self}/modules/ssh/"		
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
	];

	programs.git.enable  = true;
	programs.tmux.enable = true;
	programs.fish.enable = true;
}
