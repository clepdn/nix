{ config, lib, modulesPath, ... }:
{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = { 
      availableKernelModules = [ "xhci_pci" "nvme" "ahci" "usb_storage" "usbhid" "sd_mod" ];
      kernelModules = [ ];
      luks.devices."luks-fcfa46e1-ca4f-42ee-9565-8d3e3053661b".device = "/dev/disk/by-uuid/fcfa46e1-ca4f-42ee-9565-8d3e3053661b";
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    blacklistedKernelModules = [ "amdgpu" ];
  };

  fileSystems = {
    "/" = { 
      device = "/dev/mapper/luks-fcfa46e1-ca4f-42ee-9565-8d3e3053661b";
      fsType = "btrfs";
    };

    "/home" = {
      device = "/dev/mapper/luks-fcfa46e1-ca4f-42ee-9565-8d3e3053661b";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

    "/nix" = {
      device = "/dev/mapper/luks-fcfa46e1-ca4f-42ee-9565-8d3e3053661b";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/A194-413E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  swapDevices = [ 
    { device = "/dev/mapper/luks-7bee7b38-eff2-49f8-b996-130e4927a566"; }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
