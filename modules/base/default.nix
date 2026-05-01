{ config, pkgs, lib, self, inputs, ... }:
{
	imports = [
		"${self}/modules/ssh/"
		"${self}/modules/nix/"
	];

	boot.blacklistedKernelModules = [ "algif_aead" ]; # vuln mitigation

	environment.systemPackages = with pkgs; [
		jq
		file
		vim
		wget
		kitty # including in base cause pagers freak out when TERM=xterm-kitty
		btop
		mosh 
		wl-clipboard
		mosh
		openssl
		psmisc # killall
		inputs.agenix.packages.${pkgs.system}.default
	];

	programs.git.enable  = true;
	programs.tmux.enable = true;
	programs.fish.enable = true;
	programs.neovim.enable  = true;
	documentation.man.cache.enable = false;
	documentation.man.man-db.enable = false;

	networking.networkmanager.enable = true;
}
