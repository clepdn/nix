{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.myNixOS.pavement;
  
  # Expects inputs.pavement to contain pre-built output:
  #   build/          - sveltekit build output
  #   node_modules/   - production dependencies
  #   package.json
  src = inputs.pavement;
in
{
  options.myNixOS.pavement = {
    enable = lib.mkEnableOption "Pavement SvelteKit site";

    port = lib.mkOption {
      type = lib.types.port;
      default = 3400;
      description = "Port to run the server on";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pavement";
      description = "Directory for persistent data";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "pavement";
      description = "User to run the service as";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "pavement";
      description = "Group to run the service as";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.group;
      home = cfg.dataDir;
    };

    users.groups.${cfg.group} = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.pavement = {
      description = "Pavement SvelteKit Site";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NODE_ENV = "production";
        PORT = toString cfg.port;
        HOST = "0.0.0.0";
        BODY_SIZE_LIMIT = "Infinity";
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.dataDir;
        ExecStart = "${pkgs.nodejs_22}/bin/node ${src}/build/index.js";
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        ReadWritePaths = [ cfg.dataDir ];
      };
    };
  };
}
