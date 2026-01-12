{ pkgs, ... }:
with pkgs; [
	vim 
	wget
	kitty
	mpv
	wl-clipboard
	file
	vesktop
	vicinae
	findutils
	mlocate
	kdePackages.kwalletmanager
	sbctl # secure boot
	powertop
	mesa-demos # glxinfo, glxgears
	vulkan-tools
	pciutils
	nix-index # nix-locate
	btop
	gnome-software
	rofimoji
	fuzzel
	hyfetch
	fastfetch
	gnome-font-viewer
	prismlauncher
	krita
	mosh
	minio-client
]
