{ config, ... }: {
  age.secrets.hermes-env = {
    file = ../../../secrets/hermes.env.age;
    owner = "hermes";
    group = "hermes";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;

    settings = {
      model = {
        # Native DeepSeek API — no aggregator middleman.
        # V3 (fast/cheap): deepseek-chat
        # V4 Pro (reasoning): deepseek-v4-pro
        # Legacy reasoner (R1): deepseek-reasoner
        default = "deepseek-v4-pro";
        base_url = "https://api.deepseek.com/v1";
      };
      toolsets = [ "all" ];
      terminal = {
        backend = "local";
        timeout = 180;
      };
      memory = {
        memory_enabled = true;
        user_profile_enabled = true;
      };
    };

    environmentFiles = [ config.age.secrets.hermes-env.path ];

    container = {
      enable = true;
      backend = "podman";
      hostUsers = [ "callie" ];
    };

    # Pull in fastapi/uvicorn (web) and ptyprocess (pty) so the dashboard
    # service and embedded chat terminal work.
    extraDependencyGroups = [ "web" "pty" ];

    addToSystemPackages = true;
  };

  # Dashboard as a separate systemd service, bound to all interfaces.
  systemd.services.hermes-dashboard = {
    description = "Hermes Agent Web Dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "hermes-agent.service" ];
    environment = {
      HERMES_HOME = "/var/lib/hermes/.hermes";
      HERMES_MANAGED = "true";
      # Skip container routing — the dashboard runs natively on the host.
      HERMES_DEV = "1";
    };
    serviceConfig = {
      ExecStart = "${config.services.hermes-agent.package}/bin/hermes dashboard --host 0.0.0.0 --port 9119 --no-open --insecure";
      User = "hermes";
      Group = "hermes";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

}
