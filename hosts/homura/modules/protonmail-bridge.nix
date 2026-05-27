{ pkgs, ... }:
{
  users.users.protonmail-bridge = {
    isSystemUser = true;
    group = "protonmail-bridge";
    home = "/var/lib/protonmail-bridge";
  };
  users.groups.protonmail-bridge = {};

  systemd.services.protonmail-bridge = {
    description = "Proton Mail Bridge";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    environment = {
      HOME            = "/var/lib/protonmail-bridge";
      XDG_DATA_HOME   = "/var/lib/protonmail-bridge";
      XDG_CONFIG_HOME = "/var/lib/protonmail-bridge";
      XDG_CACHE_HOME  = "/var/cache/protonmail-bridge";
    };

    serviceConfig = {
      ExecStart    = "${pkgs.protonmail-bridge}/bin/protonmail-bridge --noninteractive";
      User         = "protonmail-bridge";
      Group        = "protonmail-bridge";
      StateDirectory = "protonmail-bridge";
      CacheDirectory = "protonmail-bridge";
      Restart      = "on-failure";
      RestartSec   = "5s";
    };
  };

  # For one-time account setup, run as the service user:
  #   sudo -u protonmail-bridge \
  #     env HOME=/var/lib/protonmail-bridge \
  #         XDG_DATA_HOME=/var/lib/protonmail-bridge \
  #         XDG_CONFIG_HOME=/var/lib/protonmail-bridge \
  #     protonmail-bridge --cli
  environment.systemPackages = [ pkgs.protonmail-bridge ];
}
