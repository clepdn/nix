{ config, lib, ... }:
let
  inherit (import ./shared.nix) groupUsers domain root;

  port443 = [
    { addr = "[::]";    port = 443; ssl = true; extraParameters = [ "http2" ]; }
    { addr = "0.0.0.0"; port = 443; ssl = true; extraParameters = [ "http2" ]; }
  ];

  mkUserLocations = user: {
    "/~${user}/".alias = "${root}/${user}/";
    "= /${user}".return = "301 https://${domain}/~${user}/";
  };
in {
  security.acme.certs.${domain} = {
    domain = domain;
    group = "nginx";
    inherit (config.myNixOS.porkbunDns) dnsProvider environmentFile;
  };

  services.nginx.virtualHosts.${domain} = {
    forceSSL = true;
    listen = port443;
    useACMEHost = domain;
    locations =
      { "/".alias = "${root}/index/"; }
      // lib.foldl' (a: b: a // b) {} (map mkUserLocations groupUsers);
  };
}
