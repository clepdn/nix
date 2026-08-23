{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.codexRemoteControl;

  serviceUser =
    if cfg.user != null && lib.hasAttr cfg.user config.users.users then
      config.users.users.${cfg.user}
    else
      {
        home = "/var/empty";
        shell = "${pkgs.shadow}/bin/nologin";
      };

  serviceGroup =
    if cfg.group != null then
      cfg.group
    else if cfg.user != null && lib.hasAttr cfg.user config.users.users then
      config.users.users.${cfg.user}.group
    else
      "nogroup";

  codexExecutable = lib.getExe cfg.package;
  serviceEnvironment = {
    HOME = serviceUser.home;
    CODEX_HOME = cfg.codexHome;
    SHELL = serviceUser.shell;
  }
  // cfg.environment;
  environmentExports = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") serviceEnvironment
  );

  codexArgs = lib.concatStringsSep " " [
    "-c"
    (lib.escapeShellArg "check_for_update_on_startup=false")
    "-c"
    (lib.escapeShellArg ''cli_auth_credentials_store="file"'')
  ];
  codexRemoteControl = pkgs.writeShellApplication {
    name = "codex-remote-control-service";
    runtimeInputs = [ cfg.package ] ++ cfg.extraPackages;
    text = ''
      exec ${codexExecutable} ${codexArgs} remote-control start
    '';
  };

  makeCodexHelper =
    {
      name,
      command,
      description,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [ cfg.package ];
      text = ''
        # ${description}
        ${environmentExports}
        exec ${codexExecutable} ${codexArgs} ${command} "$@"
      '';
    };

  codexRemotePair = makeCodexHelper {
    name = "codex-remote-pair";
    command = "remote-control pair";
    description = "Pair this Codex Remote Control instance with a client.";
  };
  codexRemoteLogin = makeCodexHelper {
    name = "codex-remote-login";
    command = "login";
    description = "Authenticate Codex with the file-backed credential store.";
  };

  codexRemoteLoginStatus = makeCodexHelper {
    name = "codex-remote-login-status";
    command = "login status";
    description = "Show file-backed Codex authentication status.";
  };

  codexRemoteDoctor = makeCodexHelper {
    name = "codex-remote-doctor";
    command = "doctor --summary";
    description = "Show a redacted Codex runtime diagnostic summary.";
  };

  codexRemoteCheck = pkgs.writeShellApplication {
    name = "codex-remote-check";
    runtimeInputs = [ cfg.package ];
    text = ''
      ${environmentExports}
      ${codexExecutable} ${codexArgs} remote-control --help >/dev/null
      ${codexExecutable} ${codexArgs} remote-control pair --help >/dev/null
      printf '%s\n' "Codex Remote Control commands are available."
    '';
  };
in
{
  options.services.codexRemoteControl = {
    enable = lib.mkEnableOption "Codex Remote Control";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.codex;
      description = "Pinned Codex package used by the service and helper commands.";
    };

    user = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Existing non-root account that owns Codex state and workspaces.";
    };

    group = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Group used to run the service; defaults to the user's primary group.";
    };

    codexHome = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Persistent private directory containing Codex state and credentials.";
    };

    workingDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Absolute working directory for the service.";
    };

    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = "Commands available to Codex outside project-specific dev shells.";
    };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Non-secret environment, such as proxy or custom CA settings.";
    };

    restartSec = lib.mkOption {
      type = lib.types.str;
      default = "10s";
      description = "Delay before restarting the foreground process.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.user != null;
        message = "services.codexRemoteControl.user must be set when the service is enabled.";
      }
      {
        assertion = cfg.user != "root";
        message = "services.codexRemoteControl.user must not be root.";
      }
      {
        assertion = cfg.user != null && lib.hasAttr cfg.user config.users.users;
        message = "services.codexRemoteControl.user must name an existing user.";
      }
      {
        assertion = cfg.codexHome != null && lib.hasPrefix "/" cfg.codexHome;
        message = "services.codexRemoteControl.codexHome must be an absolute path.";
      }
      {
        assertion = cfg.workingDirectory != null && lib.hasPrefix "/" cfg.workingDirectory;
        message = "services.codexRemoteControl.workingDirectory must be an absolute path.";
      }
      {
        assertion =
          let
            mainProgram =
              if cfg.package.meta ? mainProgram then cfg.package.meta.mainProgram else lib.getName cfg.package;
          in
          (builtins.tryEval (lib.getExe cfg.package)).success && mainProgram == "codex";
        message = "services.codexRemoteControl.package must expose a codex executable.";
      }
    ];

    environment.systemPackages = [
      cfg.package
      codexRemoteCheck
      codexRemoteDoctor
      codexRemoteLogin
      codexRemoteLoginStatus
      codexRemotePair
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.codexHome} 0700 ${cfg.user} ${serviceGroup} -"
      "z ${cfg.codexHome}/auth.json 0600 ${cfg.user} ${serviceGroup} -"
    ];

    systemd.services.codex-remote-control = {
      description = "Codex Remote Control";
      documentation = [
        "https://developers.openai.com/codex/developer-commands#codex-remote-control"
      ];

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      path = [ cfg.package ] ++ cfg.extraPackages;
      environment = serviceEnvironment;

      unitConfig = {
        ConditionPathExists = "${cfg.codexHome}/auth.json";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 10;
      };

      restartTriggers = [ cfg.package ];
      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = serviceGroup;
        WorkingDirectory = cfg.workingDirectory;
        ExecStart = "${codexRemoteControl}/bin/codex-remote-control-service";

        Restart = "always";
        RestartSec = cfg.restartSec;
        TimeoutStopSec = "30s";
        KillMode = "control-group";
        UMask = "0077";

        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
