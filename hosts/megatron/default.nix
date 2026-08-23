{ self, pkgs, clib, ... }:
{
	imports = clib.importFolder ./modules ++ [
	      ./hardware-configuration.nix
	      "${self}/users/callie/graphicalSession.nix"
	      "${self}/modules/base"
	      "${self}/modules/pipewire"
	      "${self}/modules/doh"
	      "${self}/modules/avahi"
	      "${self}/modules/steam"
	      "${self}/modules/tools"
	      "${self}/modules/tz/ny.nix"
	      "${self}/modules/nix-ld/steam-run.nix"
              "${self}/modules/nix-ld/slippi.nix"
              "${self}/modules/nix-ld/mcef.nix"
              "${self}/modules/podman"
              
	];

	myNixOS.nix.homuraBuilder.enable = false;
	myNixOS.nix.signing.enable = true;
	myNixOS.podman.enable = true;

	powerManagement.cpuFreqGovernor = "performance";
	environment.sessionVariables.mesa_glthread = "true";

	networking.hostName = "megatron";

	boot = {
		loader.systemd-boot.enable = true;
		loader.efi.canTouchEfiVariables = true;
		initrd.luks.devices."luks-7bee7b38-eff2-49f8-b996-130e4927a566".device = "/dev/disk/by-uuid/7bee7b38-eff2-49f8-b996-130e4927a566";
		binfmt.emulatedSystems = [ "aarch64-linux" ];
	};

	services.xserver.enable = true;
	services.displayManager.sddm.enable = true;
	services.desktopManager.plasma6.enable = true;

	services.udev.extraRules = ''
	  ACTION=="add", SUBSYSTEM=="pci", KERNEL=="0000:11:00.*", ATTR{power/wakeup}="disabled"
	  # Moondrop Dawn Pro 2 (Savitech chip, 35d8:011d) — rw on its hidraw node for
	  # WebHID control (hub.moondroplab.tech). Granted via the plugdev group rather
	  # than TAG+="uaccess": extraRules lands in 99-local.rules, which runs *after*
	  # systemd's 73-seat-late.rules that fires the uaccess builtin, so the tag is
	  # set too late to produce an ACL. GROUP+MODE has no such ordering dependency.
	  KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="35d8", MODE="0660", GROUP="plugdev"
	'';

	environment.systemPackages = with pkgs; [ 
		arch-install-scripts
		nodejs
		python3
	];

	system.stateVersion = "26.05";

}
