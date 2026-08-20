{ pkgs, ... }:
{
  # Home Assistant connects to this Wyoming satellite over the tailnet. The
  # satellite captures from DeepFilter's explicitly named virtual source,
  # which wraps the Yeti microphone, and plays replies on PipeWire's default
  # sink.
  services.wyoming.satellite = {
    enable = true;
    user = "callie";
    name = "Megatron";

    microphone.command = "pw-record --target deepfilter-source --rate 16000 --channels 1 --format s16 --raw -";
    microphone.autoGain = 0;
    microphone.noiseSuppression = 0;
    vad.enable = false;
    sound.command = "pw-play --rate 22050 --channels 1 --format s16 --raw -";
    sounds = {
      awake = ../../../assets/voice-assistant-awake.wav;
      done = ../../../assets/voice-assistant-done.wav;
    };

    # Keep wake-word detection local; only the satellite is reachable by Home
    # Assistant. Restrict detection to "Okay Nabu" to avoid activation by the
    # other packaged wake words.
    extraArgs = [
      "--wake-uri" "tcp://127.0.0.1:10400"
      "--wake-word-name" "okay_nabu"
    ];
  };

  services.wyoming.openwakeword = {
    enable = true;
    uri = "tcp://127.0.0.1:10400";
  };

  # The satellite's protocol endpoint carries microphone audio and playback.
  # Restrict it to the tailnet instead of exposing it on the local network.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 10700 ];

  # The satellite module only places ALSA utilities on its service PATH;
  # PipeWire supplies pw-record and pw-play for the desktop audio session.
  systemd.services.wyoming-satellite.path = [ pkgs.pipewire ];
}
