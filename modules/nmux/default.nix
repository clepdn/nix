{ config, lib, pkgs, ... }:

let
  nmux = pkgs.writeShellScriptBin "nmux" ''
    export PATH="${lib.makeBinPath [ pkgs.inotify-tools pkgs.psmisc ]}:$PATH"
    exec ${pkgs.fish}/bin/fish ${./nmux.fish} "$@"
  '';
in
{
  home.packages = [ nmux ];
}
