{ config, lib, ... }:

let
  servicePort = 5580;
  dataDir = "/var/lib/matter-server";
in
{
  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
    "d ${dataDir}/data 0755 root root -"
  ];

  virtualisation.oci-containers.containers.matter-server = {
    image = "ghcr.io/home-assistant-libs/python-matter-server:stable";
    hostname = "matter-server";
    volumes = [
      "${dataDir}/data:/data"
      "/run/dbus:/run/dbus:rw"
    ];
    cmd = [ "--storage-path" "/data" "--port" (toString servicePort) ];
    extraOptions = [
      "--network=host"
    ];
    log-driver = "journald";
  };

  systemd.services.podman-matter-server = {
    after = [ "bluetooth.service" ];
    requires = [ "bluetooth.service" ];
  };

  networking.firewall = {
    allowedTCPPorts = [ servicePort ];
    allowedUDPPorts = [ 5353 5540 ];
  };
}
