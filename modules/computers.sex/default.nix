{ self, lib, ... }:
let
  inherit (import ./shared.nix) groupUsers domain root;
in {
  imports = [
    ./nginx.nix
    ./jail.nix
    "${self}/users/emelia"
    "${self}/users/callie"
  ];

  users.groups.computer-sex = {};

  users.users = lib.genAttrs groupUsers (_: { extraGroups = [ "computer-sex" ]; });

  systemd.tmpfiles.rules = [
    "d ${root}                       0755 root    root         -"
    "d ${root}/index                 0775 root    computer-sex -"
  ] ++ map (user: "d ${root}/${user} 0775 ${user} computer-sex -") groupUsers;
}
