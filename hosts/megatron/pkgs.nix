{ pkgs ? import <nixpkgs> {} }:

pkgs.buildEnv {
  name = "my-packages";
  paths = with pkgs; [
    vim
    git
    htop
  ];
}{ pkgs ? import <nixpkgs> {} }:

pkgs.buildEnv {
  name = "my-packages";
  paths = with pkgs; [
    vim
    git
    htop
  ];
}
