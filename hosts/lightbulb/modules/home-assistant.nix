{ config, lib, ... }:

let
  servicePort = 8123;
  dataDir = "/var/lib/home-assistant";
in
{
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  virtualisation.oci-containers.backend = "podman";

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  systemd.services.podman-home-assistant = {
    after = [ "bluetooth.service" ];
    requires = [ "bluetooth.service" ];
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
    "d ${dataDir}/config 0755 root root -"
  ];

  virtualisation.oci-containers.containers.home-assistant = {
    image = "ghcr.io/home-assistant/home-assistant:stable";
    hostname = "home-assistant";
    environment = {
      TZ = config.time.timeZone;
    };
    volumes = [
      "${dataDir}/config:/config"
      "/run/dbus:/run/dbus:ro"
    ];
    extraOptions = [
      "--network=host"
      "--cap-add=NET_ADMIN"
      "--cap-add=NET_RAW"
    ];
    log-driver = "journald";
  };

  networking.firewall.allowedTCPPorts = [ servicePort ];
}
