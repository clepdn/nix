{ pkgs, ... }:
{
  age.identityPaths = [ "/etc/age/identity" ];
  systemd.services.generate-pq-agekey = {
    wantedBy = [ "multi-user.target" ];
    before = [ "agenix.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f /etc/age/identity ]; then
      mkdir -p /etc/age
      ${pkgs.age}/bin/age-keygen -pq -o /etc/age/identity
      chmod 600 /etc/age/identity
      fi
    '';
  };
}
