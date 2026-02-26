{ config, pkgs, lib, ... }:
{
  hardware.bluetooth = {
	enable = true;
	powerOnBoot = true;
	settings = {
		General = {
			# Show battery charge of connected devices.
			Experimental = true;
			# Faster connections. Uses more power.
			FastConnectable = false;
		};
		Policy = {
			AutoEnable = true;
		};
	};
  };
}
