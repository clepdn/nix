{ ... }:
{
  # Nouveau with GSP firmware support for Turing (TU104 / 2080 Super).
  # GSP lets nouveau do power management and run at real clock speeds
  # instead of being stuck at boot/idle clocks. Requires kernel 6.8+.
  hardware.graphics.enable = true;

  # Pull in linux-firmware, which includes the NVIDIA GSP blobs that
  # land at /lib/firmware/nvidia/tu104/ and are picked up by nouveau.
  hardware.enableRedistributableFirmware = true;

  # Use the generic modesetting DDX; nouveau provides KMS directly.
  services.xserver.videoDrivers = [ "modesetting" ];

  # Enable GSP mode for nouveau.
  boot.extraModprobeConfig = ''
    options nouveau GSP_ENABLE=1
  '';

  # Keep the proprietary nvidia module from autoloading, if present.
  boot.blacklistedKernelModules = [ "nvidia" "nvidia_uvm" "nvidia_drm" "nvidia_modeset" ];
}
