{ pkgs, ... }:
{
  imports = [ 
    ./steam-run.nix
    ./default.nix
  ];

  # xkbcommon looks for XKB data at the hardcoded /usr/share/X11/xkb path.
  environment.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";

  programs.nix-ld.libraries = with pkgs; [
    fuse
    # Electron / Chromium core
    stdenv.cc.cc        # libstdc++
    zlib
    glib
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    expat
    libdrm
    libxkbcommon
    mesa              # libGL / libgbm
    libglvnd
    alsa-lib
    pango
    cairo
    fontconfig
    freetype
    libnotify
    libuuid
    systemd           # libudev
    librsvg
    p11-kit
    libgpg-error

    # X libs Chromium pokes at
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    libxscrnsaver
    libxtst
    libxshmfence

    # GTK (Electron menus/dialogs)
    gtk3
    gdk-pixbuf

    # Slippi-specific: it bundles Dolphin which wants these
    curl
    openssl
    libusb1
    libSM
    gmp
  ];
}
