{ pkgs, ... }:
{
  # steam-run multiPkgs — mirrors the FHS env steam-run provides
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/st/steam/package.nix

  imports = [ 
    ./default.nix
  ];

  programs.nix-ld.libraries = with pkgs; [
      glibc
      libxcrypt
      libGL
      libdrm
      libgbm
      udev
      libudev0-shim
      libva
      vulkan-loader
      networkmanager
      libcap
      curl
  ];
}
