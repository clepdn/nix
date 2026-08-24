{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ uxplay ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  networking.firewall = {
    allowedUDPPorts = [ 5353 ];
    allowedTCPPortRanges = [
      { from = 35000; to = 35002; }
    ];
    allowedUDPPortRanges = [
      { from = 35000; to = 35002; }
    ];
  };
}
