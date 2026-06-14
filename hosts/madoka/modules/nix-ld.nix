{ pkgs, self, ... }:
{
  imports = [
    "${self}/modules/nix-ld/steam-run.nix"
    "${self}/modules/nix-ld/slippi.nix"
  ];
  # xkbcommon looks for XKB data at the hardcoded /usr/share/X11/xkb path.
  # Point it at the real location so unpatched binaries don't SIGSEGV on startup.
  environment.sessionVariables.XKB_CONFIG_ROOT = "${pkgs.xkeyboard-config}/share/X11/xkb";

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # i do not remember why i needed these 
      glib
      alsa-lib
      libusb1
      libSM
      pango
      gdk-pixbuf
      fontconfig
      xorg.libX11
      fribidi
      harfbuzz
      librsvg
      freetype
      xorg.libxcb
      p11-kit
      gmp
      libgpg-error
      e2fsprogs
      libxkbcommon
      zlib           
      expat
      stdenv.cc.cc.lib
    ];
  };
}
