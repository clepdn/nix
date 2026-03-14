{ config, pkgs, self, lib, ... }:

let
  atlogin = pkgs.buildGoModule {
    pname = "atlogin";
    version = "unstable-2026-01-15";
    src = pkgs.fetchFromGitHub {
      owner = "apenwarr";
      repo = "atlogin";
      rev = "943b11de2f5592a6680a826c67e763f292c664ff";
      hash = "sha256-E4B1zj3jYxVw9LKxLkJjNwa72UfrrkRJj4sxPnHhdsA=";
    };
    vendorHash = "sha256-bmoNRyzxIKZmz7hzDKhMSulYZ67PmqpnDzYxtTQhI0o=";
    subPackages = [ "cmd/atlogin" ];
  };
in
{
  age.secrets.atlogin = {
    file = "${self}/secrets/atlogin.age";
    owner = "atlogin";
    group = "atlogin";
    mode = "400";
  };

  users.users.atlogin = {
    isSystemUser = true;
    group = "atlogin";
    home = "/var/lib/atlogin";
    createHome = true;
  };
  users.groups.atlogin = { };

  systemd.services.atlogin = {
    description = "ATProto OIDC provider";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "atlogin";
      Group = "atlogin";
      WorkingDirectory = "/var/lib/atlogin";
      # config.json is the agenix secret — atlogin reads it from its working dir
      ExecStartPre = "${pkgs.coreutils}/bin/ln -sf ${config.age.secrets.atlogin.path} /var/lib/atlogin/state/config.json";
      ExecStart = "${atlogin}/bin/atlogin";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
