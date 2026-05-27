{ pkgs, config, ... }:
{
  age.identityPaths = [ "${config.home.homeDirectory}/.age/identity" ];

  systemd.user.services.generate-pq-agekey = {
    Unit = {
      Description = "Generate user PQ age identity key";
      After = "default.target";
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "generate-pq-agekey" ''
        if [ ! -f "$HOME/.age/identity" ]; then
          mkdir -p "$HOME/.age"
          ${pkgs.age}/bin/age-keygen -pq -o "$HOME/.age/identity"
          chmod 600 "$HOME/.age/identity"
          chown ${config.home.username}:users "$HOME/.age/identity"
        fi
      '';
    };
    Install.WantedBy = [ "default.target" ];
  };
}
