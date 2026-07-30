{ config, pkgs, lib, inputs, agenixPackage ? inputs.agenix.packages.${pkgs.system}.default, ... }:
{
	imports = [
		../ssh
		../nix
		../age-pq
	];

	options.myNixOS.graphical = lib.mkOption {
		type = lib.types.bool;
		default = false;
	};

	config = {
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
			agenixPackage
			busybox
			nix-search
			nmap
			libarchive # bsdtar

			# Manpage stuff
			man-pages
			man-pages-posix
		];

		# These take ages to build
		documentation = lib.mkMerge [
			{
				man.man-db.enable = true;
				dev.enable = true;
			}
			# `man.generateCaches` was renamed to `man.cache.enable` after 25.11.
			# clockwork (uConsole) builds against nixos-uconsole's 25.11 pin, while
			# everything else tracks unstable, so pick the option that exists.
			(if lib.versionAtLeast lib.version "26"
			 then { man.cache.enable = true; }
			 else { man.generateCaches = true; })
		];

		programs = {
			git.enable  = true;
			tmux.enable = true;
			fish.enable = true;
			neovim.enable  = true;
		};

		fonts.packages = with pkgs; lib.mkIf config.myNixOS.graphical
			 [
				noto-fonts
				noto-fonts-cjk-sans
				noto-fonts-cjk-serif
			];

		services.tailscale.enable = true; # Eventually we can probably do auth-keys as an agenix secret?

		networking.networkmanager.enable = true;
		users.mutableUsers = false;
	};
}
