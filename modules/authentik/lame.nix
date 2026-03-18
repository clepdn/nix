{ config, pkgs, lib, self, ... }:
{
  age.secrets.authentik = {
    file = "${self}/secrets/authentik.env.age";
    owner = "";
    group = "";
    mode  = 400;
  };
  
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };

  virtualisation.oci-containers = {
    backend = "podman";

    containers.authentik-server = {
      image = "ghcr.io/authentik/server:2024.12.1";
      cmd = [ "server" ];
      # environmentFiles = agenix
      volumes = [
        "/var/lib/authentik/media:/media"
        "/var/lib/authentik/custom-templates:/templates"
      ];
      ports = [ "9000:9000" "9443:9443" ];
    };

    containers.authentik-worker = {
      image = "docker.io/library/postgres:16-alpine";
      cmd = [ "worker" ];
      environmentFiles = [ "/run/secrets/authentik-env" ];
      volumes = [
        "/var/lib/authentik/media:/media"
        "/var/lib/authentik/custom-templates:/templates"
      ];
      dependsOn = [ "authentik-postgresql" "authentik-redis" ];
    };

    containers.authentik-postgresql = {
      image = "docker.io/library/postgres:16";
      environmentFiles = [ "/run/secrets/authentik-env" ];
      volumes = [ "/var/lib/authentik/postgresql:/var/lib/postgresql/data" ];
    };

    containers.authentik-redis = {
      image = "docker.io/library/redis:alpine";
      cmd = [ "--save" "60" "1" "--loglevel" "warning" ];
      volumes = [ "/var/lib/authentik/redis:/data" ];
    };
  };
}
