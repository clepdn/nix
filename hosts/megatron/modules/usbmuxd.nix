{ pkgs, ... }:
{
  # USB multiplexing daemon + tooling for talking to iOS devices over USB.
  services.usbmuxd.enable = true;

  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
  ];
}
