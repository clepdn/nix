{ pkgs, mypkgs, ... }:
with pkgs; [
	vim 
	wget
	kitty
	mpv
	wl-clipboard
	file
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
	rofi
	hyfetch
	fastfetch
	gnome-font-viewer
	krita
	mosh
	minio-client
	linuxPackages.nvidia_x11
	gcc
	clang
	gdb
	opencode
	zed-editor
	obs-studio
	ffmpeg-full
	qemu
	neovim-remote
	llvmPackages_20.systemLibcxxClang
	clang-tools
	steam-run
	rustup
	nixd
	appimage-run
	patchelf
	openssl

	claude-code
	gf
	blender
	nodejs_22
	mypkgs.helium
	distrobox
	gnome-network-displays
	spotify
	android-tools
]
