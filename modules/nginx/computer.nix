{ config, lib, self, ... }:
let
  cloudflareDNS = {
      dnsProvider = "cloudflare";
      environmentFile = config.age.secrets.cloudflare.path;
  };
in
{
  imports = [
    ./vhost.nix
  ];

  age.secrets.cloudflare = {
	file = "${self}/secrets/cloudflare-dns.age";
	owner = "nginx";
	group = "nginx";
	mode = "400";
  };

  myServices.acme = {
    "pds.on-her.computer" = cloudflareDNS // {
      port = 3000;
      target = "100.102.161.7";
      wildcard = true;
      extraLocationConfig = ''client_max_body_size 2G;'';
    };
    "pegasus.on-her.computer" = cloudflareDNS // {
      port = 4000;
      target = "100.102.161.7";
      wildcard = true;
      extraLocationConfig = ''client_max_body_size 2G;'';
    };
    "cobalt.on-her.computer" = cloudflareDNS // {
      port = 9000;
      target = "100.102.158.29";
    };
    "book.on-her.computer" = cloudflareDNS // {
      port = 6969;
      target = "100.116.202.116";
      extraLocationConfig = ''client_max_body_size 10G;'';
    };
    "auth.on-her.computer" = cloudflareDNS // {
      port = 9080;
      target = "100.116.202.116";
    };
    "cubit.on-her.computer" = cloudflareDNS // {
      port = 8080;
      target = "100.116.202.116";
      forwardAuth = true;
    };
    "tv.on-her.computer" = cloudflareDNS // {
      port = 8096;
      target = "100.116.202.116";
    };
    "atlogin.on-her.computer" = cloudflareDNS // {
      port = 9411;
      target = "100.116.202.116";
    };
    "dex.on-her.computer" = cloudflareDNS // {
      port = 5556;
      target = "100.116.202.116";
    };
  };
}

