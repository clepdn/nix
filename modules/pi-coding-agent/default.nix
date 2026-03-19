{ config, pkgs, lib, ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      pi-coding-agent = prev.callPackage ./package.nix { };
    })
  ];
}
