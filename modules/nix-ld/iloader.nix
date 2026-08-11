{ pkgs, ... }:
{
  imports = [ ./default.nix ];

  # iLoader bundles its GTK/WebKit stack, but relies on the host for these
  # transitive libraries.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc # libstdc++
    zlib
    fontconfig
    freetype
    libx11
    libxcb
    fribidi
    expat
    harfbuzz
    libgbm
    libdrm
    libglvnd # libGL and libEGL
    libgpg-error
    krb5 # libcom_err
  ];
}
