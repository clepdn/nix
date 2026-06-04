{ config, pkgs, self, ... }:
let
  rebuildScript = pkgs.writeShellApplication {
    name = "coral-rebuild";
    runtimeInputs = [ pkgs.nixos-container pkgs.nix ];
    text = builtins.readFile ./coral-webhook-handler.sh;
  };
in
{
  age.secrets.coralWebhookToken = {
    file = "${self}/secrets/coral-webhook-token.age";
    mode = "0400";
    owner = "root";
  };

  systemd.sockets.coral-webhook = {
    description = "Coral rebuild webhook socket";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "9123" ];
    socketConfig = {
      Accept = true;
      MaxConnections = 5;
    };
  };

  systemd.services."coral-webhook@" = {
    description = "Coral rebuild webhook handler";
    environment = {
      WEBHOOK_TOKEN_FILE = config.age.secrets.coralWebhookToken.path;
    };
    serviceConfig = {
      Type = "simple";
      ExecStart = "${rebuildScript}/bin/coral-rebuild";
      StandardInput = "socket";
      StandardOutput = "socket";
      StandardError = "journal";
      User = "root";
      Group = "root";
      SupplementaryGroups = [ config.users.groups.keys.name ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 9123 ];
}
