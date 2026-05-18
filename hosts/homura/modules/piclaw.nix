{ pkgs, lib, config, self, ... }:

let
  servicePort = 8180;
  dataDir = "/var/lib/piclaw";
in
{
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  virtualisation.oci-containers.backend = "podman";

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
    "d ${dataDir}/home 0755 root root -"
    "d ${dataDir}/workspace 0755 root root -"
  ];

  age.secrets.piclaw-keychain-key = {
    file = "${self}/secrets/piclaw-keychain-key.env.age";
    mode = "0400";
    owner = "root";
  };

  virtualisation.oci-containers.containers.piclaw = {
    image = "ghcr.io/rcarmo/piclaw:latest";
    hostname = "piclaw";
    environment = {
      TERM = "xterm-256color";
      PUID = "1000";
      PGID = "1000";
      PICLAW_WEB_PORT = toString servicePort;
      PICLAW_AUTOSTART = "1";
    };
    ports = [
      "${toString servicePort}:${toString servicePort}"
    ];
    volumes = [
      "${dataDir}/home:/config"
      "${dataDir}/workspace:/workspace"
    ];
    extraOptions = [
      "--init"
      "--shm-size=256m"
    ];
    environmentFiles = [ config.age.secrets.piclaw-keychain-key.path ];
    log-driver = "journald";
  };

  networking.firewall.allowedTCPPorts = [ servicePort ];
}
