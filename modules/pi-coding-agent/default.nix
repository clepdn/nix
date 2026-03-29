{ config, pkgs, lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      pi-coding-agent = prev.callPackage ./package.nix { };
      pi-web-access = prev.callPackage ./pi-web-access.nix { };
    })
  ];
}
