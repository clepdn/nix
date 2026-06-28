{ self, clib, ... }:
{
	imports = clib.importFolder ./modules ++ [
	      ./hardware-configuration.nix
	      "${self}/users/callie/graphicalSession.nix"
	      "${self}/modules/base"
	      "${self}/modules/pipewire"
	      "${self}/modules/plymouth"
	      "${self}/modules/tz/ny.nix"
	      "${self}/modules/nix-ld/steam-run.nix"
              "${self}/modules/nix-ld/slippi.nix"
	];

	myNixOS.nix.homuraBuilder.enable = false;

	# Nouveau is more CPU-bound than the proprietary driver; let the 7800X3D
	# actually clock up instead of sitting in powersave.
	powerManagement.cpuFreqGovernor = "performance";

	# Multithreaded GL — moves command processing off the render thread.
	# Helps the Zink→NVK path where GL apps pay extra CPU overhead.
	environment.sessionVariables.mesa_glthread = "true";

	networking.hostName = "megatron";

	boot = {
		loader.systemd-boot.enable = true;
		loader.efi.canTouchEfiVariables = true;
		initrd.luks.devices."luks-7bee7b38-eff2-49f8-b996-130e4927a566".device = "/dev/disk/by-uuid/7bee7b38-eff2-49f8-b996-130e4927a566";
	};

	services.xserver.enable = true;
	services.displayManager.sddm.enable = true;
	services.desktopManager.plasma6.enable = true;

	system.stateVersion = "26.05";
}
