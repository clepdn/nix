{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
        "sr_mod"
        "alx"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/4df77fb9-b78a-4805-995d-aa1373b64b1e";
      fsType = "ext4";
      options = [ "noatime" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/992A-518C";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    "/mnt/hdd" = {
      device = "/dev/mapper/hdd";
      fsType = "btrfs";
      options = [ "compress=zstd" "nofail" "noatime" ];
    };

    "/nix" = {
      device = "/dev/mapper/nvme";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "compress=zstd"
        "noatime"
      ];
    };
  };

  boot.initrd.luks.devices."hdd" = {
    device = "/dev/disk/by-uuid/f43fb5e6-2a5e-42a8-b0d0-fe43f495ad33";
  };

  boot.initrd.luks.devices."nvme" = {
    device = "/dev/disk/by-uuid/f41cc642-e6b8-4cf9-b39c-11aa5b391dac";
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 64 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware = {
    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };

    graphics = {
      enable = true;  # was hardware.opengl.enable before NixOS 24.11
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
