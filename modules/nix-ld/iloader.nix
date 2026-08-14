{ pkgs, lib, ... }:
let
  # iLoader was built against the libcom_err ABI supplied by e2fsprogs 1.46.
  # Current krb5 exposes only libcom_err.so.3.
  e2fsprogsCompat = (pkgs.e2fsprogs.override { withFuse = false; }).overrideAttrs (_: {
    version = "1.46.2";
    src = pkgs.fetchurl {
      url = "mirror://kernel/linux/kernel/people/tytso/e2fsprogs/v1.46.2/e2fsprogs-1.46.2.tar.xz";
      hash = "sha256-I6oJMpXJTnHvG+SQxABIccWwHSFqjLTREfpsCqw1QWg=";
    };
    # e2fsprogs 1.46 predates C23, where bool became a reserved keyword.
    postPatch = ''
      substituteInPlace lib/ext2fs/tdb.c --replace-fail "typedef int bool;" ""
    '';
    # One upstream filesystem test is incompatible with the current kernel.
    doCheck = false;
  });
  iloaderRuntimeLibraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fontconfig
    freetype
    libx11
    libxcb
    fribidi
    expat
    harfbuzz
    mesa
    libdrm
    libglvnd
    libgpg-error
    e2fsprogsCompat
    glib
    glib-networking
    gnutls
    gst_all_1.gstreamer
    gtk3
    gdk-pixbuf
    webkitgtk_4_1
    libsoup_3
    gst_all_1.gst-plugins-base
  ];
  iloaderAppImage = pkgs.appimageTools.extractType2 {
    pname = "iloader";
    version = "2.3.1";
    src = pkgs.fetchurl {
      url = "https://github.com/nab138/iloader/releases/download/v2.3.1/iloader-linux-amd64.AppImage";
      hash = "sha256-D+N+6fnr42FrunRSFCSNwtP5/+3EqCQXBsyV2WOBNlI=";
    };
  };
  iloader = pkgs.writeShellScriptBin "iloader" ''
    export APPDIR="${iloaderAppImage}"
    source "$APPDIR/apprun-hooks/linuxdeploy-plugin-gtk.sh"
    export LD_LIBRARY_PATH="${lib.makeLibraryPath iloaderRuntimeLibraries}"
    export NIX_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    export GST_PLUGIN_SYSTEM_PATH_1_0="${pkgs.gst_all_1.gst-plugins-base}/lib/gstreamer-1.0"
    cd "${iloaderAppImage}"
    exec "${iloaderAppImage}/usr/bin/iloader" "$@"
  '';
in
{
  imports = [ ./default.nix ];

  # iLoader bundles its GTK/WebKit stack, but relies on the host for these
  # transitive libraries.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc # libstdc++
    zlib
    fontconfig
    freetype
    libx11
    libxcb
    fribidi
    expat
    harfbuzz
    mesa # libgbm and EGL vendor implementation
    libdrm
    libglvnd # libGL and libEGL
    libgpg-error
    e2fsprogsCompat # libcom_err.so.2
  ];

  # The upstream AppImage pins an old WebKitGTK that aborts during EGL setup on
  # this Wayland session. Use the upstream payload with Nix's current runtime.
  environment.systemPackages = [ iloader ];
}
