{ config, lib, pkgs, ... }:
let
  cfg = config.myNixOS.ttyd;
  ttydUser = "ttyd";
  ttydGroup = "ttyd";
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
    users.users.${ttydUser} = {
      isSystemUser = true;
      group = ttydGroup;
      home = stateDir;
    };
    users.groups.${ttydGroup} = {};

    systemd.services.ttyd = {
      description = "ttyd web terminal (hardened)";
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
        User = ttydUser;
        Group = ttydGroup;
        WorkingDirectory = stateDir;

        # --- Filesystem ---
        ProtectHome = "yes";
        ProtectSystem = "strict";
        ReadWritePaths = [ stateDir ];
        PrivateTmp = true;

        # --- Capabilities ---
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        NoNewPrivileges = true;

        # --- Namespace isolation ---
        PrivateDevices = false; # need /dev/ptmx
        PrivateIPC = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";

        # --- Syscall filter ---
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

        # --- Network ---
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];

        # --- Memory / personality ---
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RemoveIPC = true;

        # --- Resource limits ---
        LimitNOFILE = 256;
        LimitNPROC = 32;
        LimitAS = "256M";
        LimitFSIZE = "50M";
        LimitCORE = 0;

        # --- Misc ---
        UMask = "0077";
        KeyringMode = "private";
        DevicePolicy = "closed";
        DeviceAllow = [
          "/dev/ptmx rw"
          "/dev/pts/[0-9]* rw"
        ];

        Restart = "on-failure";
        RestartSec = 3;

        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "ttyd";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0750 ${ttydUser} ${ttydGroup} -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
