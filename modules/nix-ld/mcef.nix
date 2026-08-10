{ pkgs, lib, ... }:
let
  mcefLibraries = with pkgs; [
    stdenv.cc.cc.lib
    nspr
    nss
    glib
    dbus
    atk
    at-spi2-atk
    at-spi2-core
    cups
    libgbm
    libxkbcommon
    expat
    cairo
    pango
    systemd
    alsa-lib
    fontconfig
    freetype
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
  ];
in
{
  imports = [ ./default.nix ];

  # MCEF/JCEF ships an unpatched Chromium shared library. nix-ld supports helper
  # executables, while the launcher supplies the library path for JVM dlopen().
  programs.nix-ld.libraries = mcefLibraries;

  environment.systemPackages = [
    (pkgs.writeShellApplication {
      name = "prismlauncher";
      text = ''
        export LD_LIBRARY_PATH="${lib.makeLibraryPath mcefLibraries}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        export XKB_CONFIG_ROOT="${pkgs.xkeyboard-config}/share/X11/xkb"
        exec ${pkgs.prismlauncher}/bin/prismlauncher "$@"
      '';
    })
  ];
}
