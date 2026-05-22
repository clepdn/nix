{ pkgs, ... }:
{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # steam-run multiPkgs — mirrors the FHS env steam-run provides
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/st/steam/package.nix
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

      # libcurl (also included in nix-ld defaults, kept explicit here)
      curl

      # nix-alien candidates
      glib
      alsa-lib
      libusb1
      libSM
      pango
      gdk-pixbuf
      fontconfig
      xorg.libX11
      fribidi
      harfbuzz
      librsvg
      freetype
      xorg.libxcb
      p11-kit
      gmp
      libgpg-error
      e2fsprogs
    ];
  };
}
