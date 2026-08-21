{ ... }:
{
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.oci-containers.containers.wyoming-parakeet = {
    image = "docker.io/lmo3/wyoming-onnx-stt:latest";
    # The container listens on 10300; retain that port for Faster Whisper and
    # publish Parakeet separately for an independent Home Assistant pipeline.
    ports = [ "10301:10300" ];
    volumes = [
      "/var/lib/wyoming-parakeet:/data:rw"
    ];
    environment = {
      STT_MODEL = "nemo-parakeet-tdt-0.6b-v3";
      STT_LANGUAGES = "hu,en,de,fr,es,it,pl,nl,cs,sk";
      STT_VAD_ENABLED = "true";
      STT_VAD_THRESHOLD = "0.7";
      STT_VAD_MIN_SPEECH_MS = "300";
      STT_VAD_MIN_SILENCE_MS = "200";
    };
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
    log-driver = "journald";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/wyoming-parakeet 0755 root root -"
  ];

  # Keep Parakeet reachable only from Home Assistant on the tailnet.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 10301 ];
}
