{ config, lib, self, ... }:
{
	boot.kernelModules = [ "bbswitch" ];
	boot.blacklistedKernelModules = [ 
		"nouveau"
		"nvidia"
	];

	boot.extraModprobeConfig = ''
		options bbswitch load_state=0 unload_state=1	
	'';

	boot.extraModulePackages = [ 
		config.boot.kernelPackages.bbswitch
		# config.boot.kernelPackages.nvidiaPackages.stable
	];

	services.xserver.videoDrivers = [ "nvidia" ];

	hardware.nvidia = {
		modesetting.enable = true;
		powerManagement.enable = false;
		open = true;
		prime = {
			offload.enable = true;
			intelBusId = "PCI:0:2:0";
			nvidiaBusId = "PCI:1:0:0";
		};
	};
}
