{ pkgs, ... }:
{
  # The correct name for this file would be graphicalSession.nix
  # Maybe I will bother changing it another day. Today? Absolutely not!
  imports = [
    ./default.nix
  ];

  users.users.callie.packages = with pkgs; [
    spotify
    feishin
    thunderbird
    qdirstat
    kdePackages.kate
  ];
}
