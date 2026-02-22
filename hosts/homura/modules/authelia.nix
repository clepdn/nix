{ config, self, ... }:
let 
  autheliaSecrets = [ "authelia-jwt" "authelia-session" "authelia-storagekey" "authelia-users.yml" ];
in {
  age.secrets = builtins.listToAttrs (map (name: {
      inherit name;
      value = {
        file  = "${self}/secrets/${name}.age";
        owner = "authelia-main";
        group = "authelia-main";
        mode  = "400";
      };
  }) autheliaSecrets);

  networking.firewall.allowedTCPPorts = [ 9091 ];

  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets."authelia-jwt".path;
      sessionSecretFile = config.age.secrets."authelia-session".path;
      storageEncryptionKeyFile = config.age.secrets."authelia-storagekey".path;
    };
    settings = {
      theme = "dark";
      server = {
        host = "0.0.0.0";
        port = 9091;
      };

      log.level = "info";

      authentication_backend = {
        file.path = "/var/lib/authelia-main/users_database.yml";
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "*.fixme.com";
            policy = "one_factor";
          }
        ];
      };

      session = {
        name = "authelia_session";
        domain = "fixme.com";
        expiration = "1h";
        inactivity = "5m";
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
    };
  };
}
