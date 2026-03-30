{ ... }:
{
  services.wyoming.piper.servers.main = {
    enable = true;
    voice = "en_US-amy-medium";
    uri = "tcp://0.0.0.0:10200";
  };
}
