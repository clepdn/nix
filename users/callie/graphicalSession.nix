{ pkgs, mypkgs, ... }:
{
  imports = [
    ./default.nix
  ];

  users.users.callie.packages = with pkgs; [
    spotify
    feishin
    thunderbird
    qdirstat
    kdePackages.kate
    ente-auth
    signal-desktop
    mpv
    pwvucontrol
    pavucontrol
    crosspipe
    livecaptions
    helvum
    mypkgs.helium

    (discord.override {
      withMoonlight = true;
    })
  ];
}
