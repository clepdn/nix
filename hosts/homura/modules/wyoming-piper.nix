{ ... }:
{
  services.wyoming.piper.servers.main = {
    enable = true;
    voice = "en_US-amy-medium";
    uri = "tcp://0.0.0.0:10200";
  };

  # TTS for Home Assistant on lightbulb; tailnet-only.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 10200 ];
}
