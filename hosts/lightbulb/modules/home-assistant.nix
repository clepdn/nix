{ config, lib, pkgs, ... }:

let
  servicePort = 8123;
  dataDir = "/var/lib/home-assistant";
  viewAssist = pkgs.fetchFromGitHub {
    owner = "dinki";
    repo = "view_assist_integration";
    rev = "2026.6.0"; # pin to the release tag
    hash = "sha256-jnnKHQh3qK0mJ9p37TVQI9Uzkh/L6iPWtR6wAxDyL24=";
  };
in
{
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
      OPENAI_BASE_URL = "https://bridget.on-her.computer/v1";
    };
    volumes = [
      "${dataDir}/config:/config"
      "/run/dbus:/run/dbus:ro"
      "${viewAssist}/custom_components/view_assist:/config/custom_components/view_assist:ro,z"
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
