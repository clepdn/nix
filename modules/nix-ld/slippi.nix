{ pkgs, ... }:
{
  imports = [ 
    ./steam-run.nix
    ./default.nix
  ];

  programs.nix-ld.libraries = with pkgs; [
    fuse
  ];
}
