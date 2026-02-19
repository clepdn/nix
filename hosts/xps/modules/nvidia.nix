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
		config.boot.kernelPackages.nvidiaPackages.stable
	];

	hardware.nvidia.open = true;
}
