{ ... }:
{ 
  services.avahi = 
  {
    enable    = true;
    nssmdns4  = true;
    reflector = true;
    publish   = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  networking.firewall.allowedUDPPorts = [ 5353 ];
}
