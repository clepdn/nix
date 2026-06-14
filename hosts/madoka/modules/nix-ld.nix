{ pkgs, self, ... }:
{
  imports = [
    "${self}/modules/nix-ld/steam-run.nix"
    "${self}/modules/nix-ld/slippi.nix"
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libusb1
      libSM
      gmp
    ];
  };
}
