{ pkgs, lib, config, self, inputs, ... }:

{
  age.secrets.happy = {
    file = "${self}/secrets/happy.env.age";
    mode = "400";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/happy 0755 root root -"
    "d /var/lib/happy/pglite 0755 root root -"
  ];

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers."happy-server" = {
    image = "localhost/happy-server:local";
    cmd = [ "sh" "-c" "pnpm --filter happy-server standalone migrate && pnpm --filter happy-server standalone serve" ];
    environmentFiles = [ config.age.secrets.happy.path ];
    environment = {
      DB_PROVIDER = "pglite";
      PGLITE_DIR = "/data/pglite";
      PORT = "3000";
    };
    ports = [ "3100:3000/tcp" ];
    volumes = [ "/var/lib/happy/pglite:/data/pglite:rw" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=happy"
      "--network=happy_default"
    ];
  };

  # Build the happy-server image from the pinned source
  systemd.services."podman-build-happy-server" = {
    path = [ pkgs.podman ];
    script = ''
      podman build \
        -t localhost/happy-server:local \
        -f ${inputs.happy-src}/Dockerfile.server \
        ${inputs.happy-src}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    wantedBy = [ "multi-user.target" ];
  };

  # Create the container network before any containers start
  systemd.services."podman-network-happy_default" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f happy_default";
    };
    script = ''
      podman network inspect happy_default || podman network create happy_default
    '';
    wantedBy = [ "multi-user.target" ];
  };

  systemd.services."podman-happy-server" = {
    after    = [ "podman-network-happy_default.service" "podman-build-happy-server.service" ];
    requires = [ "podman-network-happy_default.service" "podman-build-happy-server.service" ];
    serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/happy/pglite";
  };

  networking.firewall.allowedTCPPorts = [ 3100 ];
}
