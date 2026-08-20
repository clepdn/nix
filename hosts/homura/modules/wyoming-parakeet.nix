{ ... }:
{
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.oci-containers.containers.wyoming-parakeet = {
    image = "ghcr.io/vrsttl/wyoming-parakeet-silero-wrapper:latest";
    # The container listens on 10300; retain that port for Faster Whisper and
    # publish Parakeet separately for an independent Home Assistant pipeline.
    ports = [ "10301:10300" ];
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

  # Keep Parakeet reachable only from Home Assistant on the tailnet.
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 10301 ];
}
