{ config, pkgs, self, ... }:
let
  tailscaleIp = "100.116.202.116";
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

  # Firewall: allow S3 and web API on tailscale interface
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ s3Port webPort ];

  environment.etc."garage.toml".text = ''
    replication_factor = 1

    metadata_dir = "/var/lib/garage/meta"
    data_dir = "/mnt/hdd/garage/data"
    db_engine = "sqlite"

    rpc_secret_file = "${config.age.secrets.garage-rpc-secret.path}"
    rpc_bind_addr = "[::]:${toString rpcPort}"

    [s3_api]
    api_bind_addr = "${tailscaleIp}:${toString s3Port}"
    s3_region = "garage"

    [s3_web]
    bind_addr = "${tailscaleIp}:${toString webPort}"

    [admin]
    api_bind_addr = "127.0.0.1:${toString adminPort}"
    admin_token_file = "${config.age.secrets.garage-admin-token.path}"
    metrics_token_file = "${config.age.secrets.garage-metrics-token.path}"
  '';

  systemd.services.garage = {
    description = "Garage S3-compatible object store";
    after = [ "network.target" "mnt-hdd.mount" ];
    wants = [ "network.target" "mnt-hdd.mount" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      GARAGE_LOG_TO_JOURNALD = "1";
    };
    serviceConfig = {
      Type = "notify";
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
