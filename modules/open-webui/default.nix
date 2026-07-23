{ config, self, ... }:

{
  age.secrets.open-webui-env = {
    file = "${self}/secrets/open-webui.env.age";
    # systemd reads EnvironmentFile as root (PID 1); the dynamic open-webui
    # user never needs to touch it, so keep it root-only.
    mode = "0400";
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8097;

    environment = {
      OPENAI_API_BASE_URL = "https://bridget.on-her.computer/v1";
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };

    environmentFile = config.age.secrets.open-webui-env.path;
  };
}
