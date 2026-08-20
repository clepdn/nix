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

  # Preserve Rofi's stock layout while using its Solarized dark counterpart.
  home-manager.users.callie.xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      show-icons: false;
    }

    * {
      background: #002b36;
      background-alt: #073642;
      foreground: #eee8d5;
      lightbg: #073642;
      lightfg: #586e75;
      selected: #586e75;
      blue: #eee8d5;
      accent: #eee8d5;
      red: #dc322f;
      normal-background: @background;
      normal-foreground: @foreground;
      alternate-normal-background: @lightbg;
      alternate-normal-foreground: @foreground;
      active-background: @background;
      active-foreground: @foreground;
      selected-normal-background: @lightfg;
      selected-normal-foreground: @foreground;
      alternate-active-background: @lightbg;
      alternate-active-foreground: @foreground;
      selected-active-background: @lightfg;
      selected-active-foreground: @foreground;
      urgent-background: @background;
      urgent-foreground: @red;
      alternate-urgent-background: @lightbg;
      alternate-urgent-foreground: @red;
      selected-urgent-background: @red;
      selected-urgent-foreground: @background;
      separatorcolor: @foreground;
      border-color: @foreground;
    }
  '';
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

    darkman
  ]);
}
