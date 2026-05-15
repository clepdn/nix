{ config, lib, pkgs, ... }:
let
  cfg = config.myNixOS.ttyd;
  ttydUser = "ttyd";
  ttydGroup = "ttyd";
  stateDir = "/var/lib/ttyd";

  # Minimal closure: only ttyd + the specific binary it launches.
  # Nothing else from the store is visible inside the sandbox.
  ttydStorePaths = lib.concatMapStringsSep "\n"
    (p: "${p}")
    (lib.attrValues (builtins.listToAttrs
      (map (p: { name = baseNameOf p; value = p; })
        (lib.splitString "\n" (builtins.readFile (
          pkgs.runCommand "ttyd-closure" {} ''
            ${pkgs.nix}/bin/nix-store --query --requisites ${pkgs.ttyd} > $out
          ''
        ))))));
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

      # Build a whitelist of only the nix store paths ttyd needs at runtime.
      # This prevents a shell escape from accessing the rest of /nix/store.
      script = let
        closurePaths = pkgs.closureInfo { rootPaths = [ pkgs.ttyd pkgs.ncurses ]; };
      in ''
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

        # --- Filesystem: tmpfs root with surgical bind mounts ---
        TemporaryFileSystem = "/:ro";
        BindReadOnlyPaths = let
          closureInfo = pkgs.closureInfo { rootPaths = [ pkgs.ttyd pkgs.ncurses ]; };
          # Each store path in the closure gets its own bind mount
          closureBinds = map (p: "${p}:${p}")
            (lib.filter (s: s != "")
              (lib.splitString "\n"
                (builtins.readFile "${closureInfo}/store-paths")));
        in closureBinds ++ [
          # minimal /etc for DNS
          "/etc/resolv.conf"
          "/etc/nsswitch.conf"
          "/etc/hosts"
          # terminfo so the pty works
          "${pkgs.ncurses}/share/terminfo:/usr/share/terminfo"
          # proc (filtered by ProcSubset)
          "/proc"
        ];
        BindPaths = [
          "${stateDir}"
          # ttyd needs a pty — /dev/ptmx + /dev/pts
          "/dev/ptmx"
          "/dev/pts"
        ];
        PrivateTmp = true;
        ProtectHome = "yes";
        ProtectSystem = "strict";
        ReadWritePaths = [ stateDir ];
        InaccessiblePaths = [
          # Even with tmpfs root, be explicit
          "-/root"
          "-/home"
          "-/boot"
        ];

        # --- Capabilities: none ---
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        NoNewPrivileges = true;

        # --- Namespace isolation ---
        PrivateUsers = false; # incompatible with TemporaryFileSystem, redundant with User= + NoNewPrivileges
        PrivateDevices = false; # need /dev/ptmx
        PrivateIPC = true;
        PrivateNetwork = false; # needs to listen
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

        # --- Network: only tailscale + loopback ---
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
        LimitCORE = 0; # no core dumps

        # --- Misc ---
        UMask = "0077";
        KeyringMode = "private";
        DevicePolicy = "closed";
        DeviceAllow = [
          "/dev/ptmx rw"
          "/dev/pts/[0-9]* rw"
        ];

        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "ttyd";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir}       0750 ${ttydUser} ${ttydGroup} -"
      "f ${stateDir}/my-bin 0750 ${ttydUser} ${ttydGroup} -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
