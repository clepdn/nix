{ config, pkgs, self, ... }:

let
  startScript = pkgs.writeShellScript "start-webhook" ''
    SECRET=$(cat ${config.age.secrets.webhook.path})
    HOOKS=$(mktemp)
    cat > $HOOKS <<EOF
    [{
      "id": "restart-myservice",
      "execute-command": "/run/wrappers/bin/sudo",
      ...
      "trigger-rule": {
        "match": {
          "type": "payload-hmac-sha256",
          "secret": "$SECRET",
          ...
        }
      }
    }]
    EOF
    exec ${pkgs.webhook}/bin/webhook -hooks $HOOKS -port 9000
  '';
in
{
  age.secrets.webhook = {
	file = "${self}/secrets/webhook.age";
	owner = "webhook-runner";
	group = "webhook-runner";
	mode = "400";
  };

  # Dedicated user
  users.users.webhook-runner = {
    isSystemUser = true;
    group = "webhook-runner";
    shell = pkgs.shadow;
  };
  users.groups.webhook-runner = {};

  # Sudo restriction
  security.sudo.extraRules = [{
    users = [ "webhook-runner" ];
    commands = [{
      command = "/run/current-system/sw/bin/systemctl restart podman-minecraft";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Webhook systemd service
  systemd.services.webhook = {
    description = "GitHub webhook listener";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      User = "webhook-runner";
      ExecStart = "${startScript}";
      Restart = "on-failure";

      # Harden it further with systemd restrictions
      NoNewPrivileges = false; # needs to be false to use sudo
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };

  # Open the port if you use a firewall
  networking.firewall.allowedTCPPorts = [ 9097 ];
}
