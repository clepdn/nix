{ config, lib, ... }:
let
  servicePort = 8283;
  dataDir = "/var/lib/letta";
in {
  age.secrets.letta-password = {
    file = ../../secrets/letta-password.age;
  };

  virtualisation.oci-containers.containers.letta = {
    image = "letta/letta:latest";
    ports = [ "${toString servicePort}:8283" ];
    volumes = [
      "${dataDir}/pgdata:/var/lib/postgresql/data"
    ];
    environment = {
      SECURE = "true";
      # Point at the local llama-cpp OpenAI-compatible endpoint
      OPENAI_API_BASE = "http://host.gateway.internal:8020/v1";
    };
    environmentFiles = [
      config.age.secrets.letta-password.path
    ];
    extraOptions = [
      "--add-host=host.gateway.internal:host-gateway"
    ];
    log-driver = "journald";
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 root root -"
    "d ${dataDir}/pgdata 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ servicePort ];
}
