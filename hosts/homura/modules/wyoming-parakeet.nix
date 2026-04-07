{ ... }:
{
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.oci-containers.containers.wyoming-parakeet = {
    image = "ghcr.io/vrsttl/wyoming-parakeet-silero-wrapper:latest";
    ports = [ "10300:10300" ];
    volumes = [
      "/var/lib/wyoming-parakeet:/data:rw"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=all"
    ];
    log-driver = "journald";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/wyoming-parakeet 0755 root root -"
  ];
}
