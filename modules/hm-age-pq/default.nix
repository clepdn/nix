{ pkgs, lib, config, ... }:
{
  home.activation.generatePqAgeKey = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    keydir="${config.home.homeDirectory}/.config/age"
    keyfile="$keydir/identity"
    if [ ! -f "$keyfile" ]; then
      mkdir -p "$keydir"
      chmod 700 "$keydir"
      ${pkgs.age}/bin/age-keygen -pq -o "$keyfile"
      chmod 600 "$keyfile"
    fi
  '';

  age.identityPaths = [ "${config.home.homeDirectory}/.config/age/identity" ];
}
