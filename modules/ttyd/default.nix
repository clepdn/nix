{ config, lib, pkgs, ... }:
let
  cfg = config.myNixOS.ttyd;
  ttydUser = "ttyd";
  ttydGroup = "ttyd";
  stateDir = "/var/lib/ttyd";
  closureInfo = pkgs.closureInfo { rootPaths = [ pkgs.ttyd pkgs.ncurses ]; };
  closureBinds = lib.filter (s: s != "")
    (lib.splitString "\n"
      (builtins.readFile "${closureInfo}/store-paths"));
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

        # --- Filesystem: tmpfs root, only closure + stateDir visible ---
        TemporaryFileSystem = "/:ro";
        BindReadOnlyPaths = map (p: "${p}:${p}") closureBinds ++ [
          "/etc/resolv.conf"
          "/etc/nsswitch.conf"
          "/etc/hosts"
          "${pkgs.ncurses}/share/terminfo:/usr/share/terminfo"
        ];
        BindPaths = [
          "${stateDir}:${stateDir}"
          "/dev/ptmx"
          "/dev/pts"
        ];
        PrivateTmp = true;
        ProtectHome = "yes";
        ProtectSystem = "strict";

        # --- Capabilities ---
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        NoNewPrivileges = true;

        # --- Namespace isolation ---
        PrivateDevices = false;
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
          "~@keyring"
          "~@chown"
          "~@setuid"
          "~@timer"
        ];
        SystemCallErrorNumber = "EPERM";

        # --- Network ---
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        IPAddressDeny = "any";
        IPAddressAllow = [
          "localhost"
          "100.64.0.0/10"
        ];
        SocketBindDeny = "any";
        SocketBindAllow = "tcp:${toString cfg.port}";

        # --- Memory / personality ---
        MemoryDenyWriteExecute = true;
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RestrictNamespaces = true;
        RemoveIPC = true;

        # --- Resource limits ---
        LimitNOFILE = 64;
        LimitNPROC = 16;
        LimitAS = "128M";
        LimitFSIZE = "10M";
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
