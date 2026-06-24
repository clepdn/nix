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
		trzsz-ssh
		openssl
		psmisc # killall
		inputs.agenix.packages.${pkgs.system}.default
		busybox
		nix-search
		nmap
		libarchive # bsdtar

		# Manpage stuff
		man-pages
		man-pages-posix
	];

	# These take ages to build
	documentation = {
		man.cache.enable  = true;
		man.man-db.enable = true;
		dev.enable = true;
	};

	programs = {
		git.enable  = true;
		tmux.enable = true;
		fish.enable = true;
		neovim.enable  = true;
	};

	services.tailscale.enable = true; # Eventually we can probably do auth-keys as an agenix secret? 
	

	networking.networkmanager.enable = true;
	users.mutableUsers = false;
}
