{ config, lib, pkgs, ... }:
let
  cfg = config.myNixOS.ttyd;
  stateDir = "/var/lib/ttyd";
in {
  options.myNixOS.ttyd = {
    enable = lib.mkEnableOption "ttyd web terminal";
    port = lib.mkOption {
      type = lib.types.port;
      default = 7681;
      description = "Port for ttyd to listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    containers.ttyd = {
      autoStart = true;
      privateNetwork = false;

      bindMounts."${stateDir}" = {
        hostPath = stateDir;
        isReadOnly = false;
      };
      config = { pkgs, ... }: {
        users.users.ttyd = {
          isSystemUser = true;
          group = "ttyd";
          home = stateDir;
        };
        users.groups.ttyd = {};

        systemd.services.ttyd = {
          description = "ttyd web terminal";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          script = ''
            exec ${pkgs.ttyd}/bin/ttyd \
              --port ${toString cfg.port} \
              --writable \
              --check-origin \
              --max-clients 3 \
              ${stateDir}/my-bin
          '';

          serviceConfig = {
            User = "ttyd";
            Group = "ttyd";
            WorkingDirectory = stateDir;

            NoNewPrivileges = true;
            CapabilityBoundingSet = "";
            RestrictNamespaces = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            RemoveIPC = true;
            ProtectClock = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
              "~@mount"
              "~@clock"
              "~@module"
              "~@raw-io"
              "~@reboot"
              "~@swap"
              "~@obsolete"
              "~@cpu-emulation"
              "~@debug"
            ];
            SystemCallErrorNumber = "EPERM";

            LimitNOFILE = 64;
            LimitNPROC = 16;
            LimitCORE = 0;

            Restart = "on-failure";
            RestartSec = 3;
          };
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
        system.stateVersion = "25.11";
      };
    };

    # Ensure state dir exists on the host
    systemd.tmpfiles.rules = [
      "d ${stateDir} 0750 root root -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
