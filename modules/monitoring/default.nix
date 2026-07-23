{ config, pkgs, lib, self, ... }:
{
  age.secrets.grafana-secret-key = {
    file = "${self}/secrets/grafana-secret-key.age";
    owner = "grafana";
    group = "grafana";
    mode = "400";
  };

  services.prometheus = {
    enable = true;
    port = 9090;

    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9100;
      };
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
        }];
      }
      {
        # coral LLM runtime exporter, running inside the `coral` nixos-container
        # (the reef config). Reached over the container veth on its private IP.
        # If the container is recreated, confirm with: nixos-container show-ip coral
        job_name = "coral";
        static_configs = [{
          targets = [ "10.233.1.2:9100" ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
      };
      security = {
        secret_key = "$__file{${config.age.secrets.grafana-secret-key.path}}";
      };
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "System Dashboards";
            orgId = 1;
            folder = "";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 10;
            allowUiUpdates = true;
            options.path = ./dashboards;
          }
        ];
      };
    };
  };

  # Open firewall for Grafana if needed
  networking.firewall.allowedTCPPorts = [ 3000 ];
}
