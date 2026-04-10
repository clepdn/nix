{ pkgs, lib }:
lib.mapAttrs'
  (n: _: { name = lib.removeSuffix ".nix" n; value = pkgs.callPackage (./. + "/${n}") {}; })
  (lib.filterAttrs
    (n: t: t == "regular" && n != "default.nix" && lib.hasSuffix ".nix" n)
    (builtins.readDir ./.))
