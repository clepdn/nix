{ lib, ... }:
let
  inherit (import ./shared.nix) groupUsers domain root;

  mkUserLocations = user: {
    "/~${user}/".alias = "${root}/${user}/";
    "= /${user}".return = "301 https://${domain}/~${user}/";
  };
in {
  services.nginx.virtualHosts.${domain}.locations =
    { "/".alias = "${root}/index/"; }
    // lib.foldl' (a: b: a // b) {} (map mkUserLocations groupUsers);
}
