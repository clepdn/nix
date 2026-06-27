{ pkgs, ... }:
{
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    mesa
    xorg.libX11
    xorg.libxcb
    fontconfig
    freetype
    zlib
    libgpg-error
    e2fsprogs
  ];
}
