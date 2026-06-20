{ self, clib, ... }:
{
	imports = clib.importFolder ./modules ++ [
	      "${self}/users/callie"
	      "${self}/modules/base"
	      "${self}/modules/pipewire"
	      "${self}/modules/plymouth"
	      "${self}/modules/tz/ny.nix"
	];

	services.xserver.enable = true;
	services.displayManager.sddm.enable = true;
	services.desktopManager.plasma6.enable = true;

	system.stateVersion = "26.05";
}
