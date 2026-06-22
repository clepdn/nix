{ self, clib, ... }:
{
	imports = clib.importFolder ./modules ++ [
	      ./hardware-configuration.nix
	      "${self}/users/callie/userSession.nix"
	      "${self}/modules/base"
	      "${self}/modules/pipewire"
	      "${self}/modules/plymouth"
	      "${self}/modules/tz/ny.nix"
	];

	myNixOS.nix.homuraBuilder.enable = false;

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
