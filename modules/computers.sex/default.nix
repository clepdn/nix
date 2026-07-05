{ self, lib, ... }:
let groupUsers = [ "callie" "emelia" "jailtest" ];
in {
  imports = [
    ./nginx.nix
    ./jail.nix
    "${self}/users/emelia"
    "${self}/users/callie"
  ];

  users.groups.computer-sex = {};

  users.users = lib.genAttrs groupUsers { extraGroups = [ "computer-sex" ]; };

  systemd.tmpfiles.rules = [
    "d /var/www/computers.sex 0755 root root -"
  ] ++ map (user: "d /var/www/computers.sex/${user} 0755 ${user} computer-sex -") groupUsers;
}
