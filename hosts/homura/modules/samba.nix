{ ... }:
{
  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "homura";
        "security" = "user";

        # Allow following symlinks (including those pointing outside the share)
        "follow symlinks" = "yes";
        "wide links" = "yes";
        "unix extensions" = "no";
      };

      share = {
        "path" = "/srv/share";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
        "create mask" = "0664";
        "directory mask" = "2775";
      };
    };
  };

  # Ensure the share directory exists
  systemd.tmpfiles.rules = [
    "d /srv/share 2775 root users -"
  ];
}
