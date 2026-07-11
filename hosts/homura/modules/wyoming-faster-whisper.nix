{ ... }:
{
  services.wyoming.faster-whisper.servers.main = {
    enable = true;
    model = "small-int8";
    language = "en";
    device = "cpu";
    uri = "tcp://0.0.0.0:10300";
  };

  # STT for Home Assistant on lightbulb; tailnet-only.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 10300 ];
}
