{ ... }:
{
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.oci-containers.containers.wyoming-faster-whisper = {
    image = "rhasspy/wyoming-whisper:latest";
    ports = [ "10300:10300" ];
    volumes = [
      "/var/lib/wyoming-faster-whisper:/data:rw"
    ];
    cmd = [
      "--model" "small-int8"
      "--language" "en"
      "--device" "cuda"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
    log-driver = "journald";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/wyoming-faster-whisper 0755 root root -"
  ];
}
