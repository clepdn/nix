{ config, pkgs, self, ... }:
let
  s3Port = 3900;
  webPort = 3902;
  adminPort = 3903;
  rpcPort = 3901;
in
{
  age.secrets.garage-rpc-secret = {
    file = "${self}/secrets/garage-rpc-secret.age";
    owner = "garage";
    group = "garage";
    mode = "400";
  };
  age.secrets.garage-admin-token = {
    file = "${self}/secrets/garage-admin-token.age";
    owner = "garage";
    group = "garage";
    mode = "400";
  };
  age.secrets.garage-metrics-token = {
    file = "${self}/secrets/garage-metrics-token.age";
    owner = "garage";
    group = "garage";
    mode = "400";
  };

  users.users.garage = {
    isSystemUser = true;
    group = "garage";
  };
  users.groups.garage = {};

  systemd.tmpfiles.rules = [
    "d /var/lib/garage/meta 0750 garage garage -"
    "d /mnt/hdd/garage/data 0750 garage garage -"
  ];

  environment.etc."garage.toml".text = ''
    replication_factor = 1

    metadata_dir = "/var/lib/garage/meta"
    data_dir = "/mnt/hdd/garage/data"
    db_engine = "sqlite"

    rpc_secret_file = "${config.age.secrets.garage-rpc-secret.path}"
    rpc_bind_addr = "[::]:${toString rpcPort}"
    rpc_public_addr = "192.168.1.10:${toString rpcPort}"

    [s3_api]
    api_bind_addr = "[::]:${toString s3Port}"
    s3_region = "garage"
    root_domain = ".s3.garage"

    [s3_web]
    bind_addr = "[::]:${toString webPort}"
    root_domain = ".web.garage"

    [admin]
    api_bind_addr = "[::]:${toString adminPort}"
    admin_token_file = "${config.age.secrets.garage-admin-token.path}"
    metrics_token_file = "${config.age.secrets.garage-metrics-token.path}"
  '';

  environment.systemPackages = [ pkgs.garage ];

  systemd.services.garage = {
    description = "Garage S3-compatible object store";
    after = [ "network.target" "mnt-hdd.mount" ];
    wants = [ "network.target" "mnt-hdd.mount" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      GARAGE_LOG_TO_JOURNALD = "1";
    };
    serviceConfig = {
      Type = "exec";
      ExecStart = "${pkgs.garage}/bin/garage server";
      Restart = "on-failure";
      RestartSec = "5s";
      User = "garage";
      Group = "garage";
      StateDirectory = "garage";
      # Garage creates its own metadata/data subdirs; just give it a home
    };
  };
}
