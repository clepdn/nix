{ pkgs, mypkgs, inputs, ... }:
let
  # Chromium doesn't recognise XDG_CURRENT_DESKTOP=niri, so Electron picks
  # basic_text and never finds ksecretd. Name the backend explicitly.
  claude-desktop = pkgs.symlinkJoin {
    name = "claude-desktop-keyring";
    paths = [ inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/claude-desktop \
        --add-flags "--password-store=gnome-libsecret"
    '';
  };
in
{
  imports = [
    ./default.nix
  ];

  services.gvfs.enable = true;
  services.udisks2.enable = true;

  users.users.callie.packages = builtins.filter
    (package: pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform package)
    (with pkgs; [
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

    claude-desktop

    inputs.codex-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default

    zoom-us
    obs-studio

    equibop
  ]);
}
