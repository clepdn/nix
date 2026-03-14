{ config, self, ... }:

{
  # Format of dex.age:
  #   DEX_ATLOGIN_SECRET=<shared secret between dex and atlogin>
  age.secrets.dex = {
    file = "${self}/secrets/dex.age";
    owner = "dex";
    group = "dex";
    mode = "400";
  };

  age.secrets.dex-jellyfin = {
    file = "${self}/secrets/dex-jellyfin.age";
    owner = "dex";
    group = "dex";
    mode = "400";
  };

  services.dex = {
    enable = true;
    environmentFile = config.age.secrets.dex.path;

    settings = {
      issuer = "https://dex.on-her.computer";

      storage = {
        type = "sqlite3";
        config.file = "/var/lib/dex/dex.db";
      };

      web.http = "127.0.0.1:5556";

      connectors = [
        {
          type = "oidc";
          id = "atlogin";
          name = "ATProto";
          config = {
            issuer = "https://atlogin.on-her.computer";
            clientID = "dex";
            clientSecret = "$DEX_ATLOGIN_SECRET";
            redirectURI = "https://dex.on-her.computer/callback";
            scopes = [ "openid" "profile" "email" ];
            insecureSkipEmailVerified = true;
          };
        }
      ];

      enablePasswordDB = true;
      # Manage local users here. Generate bcrypt hashes with:
      #   nix run nixpkgs#apacheHttpd -- -l | grep -v Compiled
      # or: htpasswd -nBC 12 "" | tr -d ':\n'
      staticPasswords = [
        # {
        #   email = "callie@on-her.computer";
        #   hash = "$2y$12$...";
        #   username = "callie";
        #   userID = "08a8684b-db88-4b73-90a9-3cd1661f5466";
        # }
      ];

      staticClients = [
        {
          id = "jellyfin";
          name = "Jellyfin";
          redirectURIs = [ "https://tv.on-her.computer/sso/OID/redirect/dex" ];
          secretFile = config.age.secrets.dex-jellyfin.path;
        }
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dex 0750 dex dex -"
  ];
}
