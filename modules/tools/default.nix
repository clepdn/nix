{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    qemu
    gcc
    clang
    clang-tools
    ffmpeg-full
    rustup
    nixd
    openssl
    blender
    nodejs_24
    distrobox
    android-tools
    nixfmt
  ];
}
