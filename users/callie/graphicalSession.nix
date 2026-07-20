{ pkgs, mypkgs, ... }:
{
  imports = [
    ./default.nix
  ];

  services.gvfs.enable = true;
  services.udisks2.enable = true;

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

    nautilus
    sshfs

    (discord.override {
      withMoonlight = true;
    })
  ];
}
