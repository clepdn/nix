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

# evaluation warning: Please replace services.authelia.instances.main.settings.{host,port,path} with services.authelia.instances.main.settings.address, before release 5.0.0


  services.authelia.instances.main = {
    enable = true;
    secrets = {
      jwtSecretFile = config.age.secrets."authelia-jwt".path;
      sessionSecretFile = config.age.secrets."authelia-session".path;
      storageEncryptionKeyFile = config.age.secrets."authelia-storagekey".path;
    };
    settings = {
      theme = "dark";
      server.address = "tcp://0.0.0.0:9091/";
      log.level = "info";

      authentication_backend = {
        file.path = config.age.secrets."authelia-users.yml".path;
      };

      access_control = {
        default_policy = "deny";
        rules = [
          {
            domain = "*.nematodes.net";
            policy = "one_factor";
            #subject = "group:<groupname>";
          }
          {
            domain = "*.on-her.computer";
            policy = "one_factor";
          }
        ];
      };

      session = {
        name = "authelia_session";
        expiration = "0";
        inactivity = "2w";
        cookies = [
          {
            domain = "nematodes.net";
            authelia_url = "https://auth.nematodes.net";
            default_redirection_url = "https://nematodes.net";
          }
          {
            domain = "on-her.computer";
            authelia_url = "https://auth.on-her.computer";
            default_redirection_url = "https://callie.on-her.computer";
          }
        ];
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";
      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
    };
  };
}
