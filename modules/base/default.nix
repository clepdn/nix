{ pkgs, self, inputs, ... }:
{
	imports = [
		"${self}/modules/ssh/"
		"${self}/modules/nix/"
		"${self}/modules/age-pq/"
	];

	# vuln mitigation
	boot.blacklistedKernelModules = [ "algif_aead" "esp4" "esp6" "rxrpc" ];

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
		trzsz-ssh # `tssh`, client for tsshd (see modules/ssh)
		openssl
		psmisc # killall
		inputs.agenix.packages.${pkgs.system}.default
	];

	programs = {
		git.enable  = true;
		tmux.enable = true;
		fish.enable = true;
		neovim.enable  = true;
	};
	# These take ages to build
	documentation.man.cache.enable = false;
	documentation.man.man-db.enable = false;

	networking.networkmanager.enable = true;
}
