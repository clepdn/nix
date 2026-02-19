{ pkgs, ... }:
{
  jovian.steam.enable         = true;
  jovian.steam.autoStart      = true;
  jovian.steam.user           = "callie";
  jovian.steam.desktopSession = "plasma";
  jovian.devices.steamdeck.enable              = true;
  jovian.devices.steamdeck.enableVendorDrivers = true;
  jovian.hardware.has.amd.gpu                  = true;

  environment.systemPackages = with pkgs; [
	galileo-mura
	jupiter-fan-control
	jupiter-hw-support
	powerbuttond
  ];
}
