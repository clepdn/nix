{ pkgs, ... }:
{
  # It's *liiiikely* dependent on these
  imports = [
    ./steam-run.nix
    ./slippi.nix
  ];

  programs.nix-ld.libraries = with pkgs; [
      fribidi
      harfbuzz
      librsvg
      p11-kit
      libgpg-error
      e2fsprogs
  ];
}
