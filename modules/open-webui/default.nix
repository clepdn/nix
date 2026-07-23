{ config, lib, self, ... }:

# Open-WebUI — a self-hosted web frontend for LLMs.
#
# It is wired to the local llm-bridge on homura (services.llm-bridge, :4040),
# which exposes an OpenAI-compatible API. The bridge requires client auth, so
# open-webui sends OPENAI_API_KEY (a UUID registered in the bridge's
# bridge-keys.json) read from an agenix env file. systemd (root) reads the
# EnvironmentFile, so the secret stays mode 0400 and never enters the store or
# the dynamic user's readable env.
#
# Like the llm-bridge itself, open-webui binds 0.0.0.0 but is only reachable
# over the tailnet (homura's firewall opens the port on tailscale0 only).
# sayaka's nginx fronts it as chat.on-her.computer.
let
  # 8080 (open-webui's default) is taken by gluetun on homura.
  servicePort = 8097;
  bridgePort = config.services.llm-bridge.settings.port or 4040;
in
{
  age.secrets.open-webui-env = {
    file = "${self}/secrets/open-webui.env.age";
    # systemd reads EnvironmentFile as root (PID 1); the dynamic open-webui
    # user never needs to touch it, so keep it root-only.
    mode = "0400";
  };

  services.open-webui = {
    enable = true;
    host = "0.0.0.0"; # reach via tailnet from sayaka's nginx (firewall scopes it)
    port = servicePort;

    # Point open-webui at the local llm-bridge (OpenAI-compatible). The API key
    # is injected via environmentFile below, not stored here.
    environment = {
      OPENAI_API_BASE_URL = "http://localhost:${toString bridgePort}/v1";
      # Telemetry off (these are the module's defaults, restated for clarity).
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
    };

    environmentFile = config.age.secrets.open-webui-env.path;
  };

  # Mirror the llm-bridge exposure: open only to the tailnet so sayaka's nginx
  # can proxy in, never the public internet directly. (nginx on sayaka fronts
  # the public TLS.)
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ servicePort ];
}
