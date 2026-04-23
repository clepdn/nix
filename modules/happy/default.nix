{ pkgs, lib, config, self, ... }:

{
  age.secrets.happy = {
    file = "${self}/secrets/happy.env.age";
    mode = "400";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/happy 0755 root root -"
    "d /var/lib/happy/postgres 0755 root root -"
    "d /var/lib/happy/redis 0755 root root -"
  ];

  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
  };

  virtualisation.oci-containers.backend = "podman";

  virtualisation.oci-containers.containers."happy-postgres" = {
    image = "docker.io/library/postgres:16-alpine";
    environmentFiles = [ config.age.secrets.happy.path ];
    volumes = [ "/var/lib/happy/postgres:/var/lib/postgresql/data:rw" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=postgres"
      "--network=happy_default"
      "--health-cmd=pg_isready -U happy"
      "--health-interval=30s"
      "--health-retries=5"
      "--health-start-period=60s"
      "--health-timeout=20s"
    ];
  };

  virtualisation.oci-containers.containers."happy-redis" = {
    image = "docker.io/library/redis:7-alpine";
    cmd = [ "redis-server" "--appendonly" "yes" "--maxmemory-policy" "noeviction" ];
    volumes = [ "/var/lib/happy/redis:/data:rw" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=redis"
      "--network=happy_default"
    ];
  };

  virtualisation.oci-containers.containers."happy-server" = {
    image = "ghcr.io/slopus/happy-server:latest";
    environmentFiles = [ config.age.secrets.happy.path ];
    ports = [ "3000:3005/tcp" ];
    dependsOn = [ "happy-postgres" "happy-redis" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=happy"
      "--network=happy_default"
    ];
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

  systemd.services."podman-happy-postgres" = {
    after    = [ "podman-network-happy_default.service" ];
    requires = [ "podman-network-happy_default.service" ];
  };
  systemd.services."podman-happy-redis" = {
    after    = [ "podman-network-happy_default.service" ];
    requires = [ "podman-network-happy_default.service" ];
  };
  systemd.services."podman-happy-server" = {
    after    = [ "podman-network-happy_default.service" ];
    requires = [ "podman-network-happy_default.service" ];
  };

  networking.firewall.allowedTCPPorts = [ 3000 ];
}
