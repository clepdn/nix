{ self, config, ... }:
{
  imports = [
    ./nginx.nix
    ./jail.nix
    "${self}/users/emelia"
  ];

  systemd.tmpfiles.rules = [
    "d /var/www/computers.sex        0755 root   root   -"
    "d /var/www/computers.sex/emelia 0775 emelia jailed -"
  ];
}
