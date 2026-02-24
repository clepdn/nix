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
	linuxPackages.nvidia_x11
	gcc
	clang
	gdb
	openai-whisper
	opencode
	obs-studio
	ffmpeg-full
	qemu_full
	neovim-remote
	llvmPackages_20.systemLibcxxClang
	clang-tools
	steam-run
	rustup
	nixd
	appimage-run
	patchelf
]
