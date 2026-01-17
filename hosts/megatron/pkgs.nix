{ pkgs ? import <nixpkgs> {} }:

pkgs.buildEnv {
  name = "my-packages";
  paths = with pkgs; [
  	nixos-rebuild
	vicinae
  ];
}
