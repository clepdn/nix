{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    libimobiledevice
    usbmuxd2
    avahi
    openssl
    altserver-linux
  ];

  services.usbmuxd = {
    enable = true;
    package = pkgs.usbmuxd2;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };
}
