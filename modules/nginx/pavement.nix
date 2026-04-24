{ config, self }:
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

  myServices.acme."underthepavement.net" = cloudflareDNS // {
    port = 3400;
    target = "100.77.12.60";
    extraLocationConfig = ''client_max_body_size 500M;'';
  };
}
