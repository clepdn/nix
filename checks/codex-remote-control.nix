{ pkgs }:

let
  fakeCodex = pkgs.writeShellScriptBin "codex" ''
    set -u
    mkdir -p "$CODEX_HOME"

    if [[ "$*" == *"remote-control --help"* || "$*" == *"remote-control pair --help"* ]]; then
      printf 'HOME=%s\nCODEX_HOME=%s\nCODEX_TEST=%s\n' "$HOME" "$CODEX_HOME" "$CODEX_TEST" > "$CODEX_HOME/helper-environment"
      exit 0
    fi

    if [[ "$*" == *"remote-control stop"* ]]; then
      if [[ -e "$CODEX_HOME/child.pid" ]]; then
        kill "$(< "$CODEX_HOME/child.pid")" 2>/dev/null || true
      fi
      touch "$CODEX_HOME/stopped"
      exit 0
    fi

    if [[ "$*" != *"remote-control start"* ]]; then
      exit 2
    fi

    printf '%s\n' "$@" > "$CODEX_HOME/argv"
    printf 'HOME=%s\nCODEX_HOME=%s\nSHELL=%s\nPATH=%s\nPWD=%s\nCODEX_TEST=%s\n' \
      "$HOME" "$CODEX_HOME" "$SHELL" "$PATH" "$PWD" "$CODEX_TEST" > "$CODEX_HOME/environment"
    command -v ps > "$CODEX_HOME/ps-path"

    ${pkgs.coreutils}/bin/sleep 3600 </dev/null >/dev/null 2>&1 &
    printf '%s\n' "$!" > "$CODEX_HOME/child.pid"
  '';
in
pkgs.testers.nixosTest {
  name = "codex-remote-control";

  nodes.machine = { ... }: {
    imports = [ ../modules/services/codex-remote-control.nix ];

    users.users.developer = {
      isNormalUser = true;
      group = "users";
      home = "/home/developer";
      shell = pkgs.bashInteractive;
    };

    services.codexRemoteControl = {
      enable = true;
      package = fakeCodex;
      user = "developer";
      codexHome = "/home/developer/.codex";
      workingDirectory = "/home/developer";
      extraPackages = [ pkgs.git ];
      environment = {
        CODEX_TEST = "expected";
      };
    };

    system.stateVersion = "25.11";
  };

  testScript = ''
    machine.start()
    machine.wait_for_unit("multi-user.target")

    # ConditionPathExists prevents an unauthenticated restart loop.
    machine.succeed("test ! -e /home/developer/.codex/auth.json")
    machine.fail("systemctl is-active --quiet codex-remote-control.service")

    machine.succeed("install -D -m 0600 /dev/null /home/developer/.codex/auth.json")
    machine.succeed("chown developer:users /home/developer/.codex/auth.json")
    machine.succeed("runuser -u developer -- codex-remote-check")
    machine.succeed("grep -Fx 'HOME=/home/developer' /home/developer/.codex/helper-environment")
    machine.succeed("grep -Fx 'CODEX_HOME=/home/developer/.codex' /home/developer/.codex/helper-environment")
    machine.succeed("grep -Fx 'CODEX_TEST=expected' /home/developer/.codex/helper-environment")
    machine.succeed("systemctl start codex-remote-control.service")
    machine.wait_for_unit("codex-remote-control.service")

    machine.succeed("test \"$(systemctl show codex-remote-control.service -p Type --value)\" = oneshot")
    machine.succeed("test \"$(systemctl show codex-remote-control.service -p RemainAfterExit --value)\" = yes")
    machine.succeed("test \"$(systemctl show codex-remote-control.service -p User --value)\" = developer")
    machine.succeed("test \"$(systemctl show codex-remote-control.service -p Group --value)\" = users")
    machine.succeed("grep -Fx remote-control /home/developer/.codex/argv")
    machine.succeed("grep -Fx start /home/developer/.codex/argv")
    machine.succeed("grep -Fx 'HOME=/home/developer' /home/developer/.codex/environment")
    machine.succeed("grep -Fx 'CODEX_HOME=/home/developer/.codex' /home/developer/.codex/environment")
    machine.succeed("grep -Fx 'PWD=/home/developer' /home/developer/.codex/environment")
    machine.succeed("grep -Fx 'CODEX_TEST=expected' /home/developer/.codex/environment")
    machine.succeed("grep -F '${fakeCodex}/bin' /home/developer/.codex/environment")
    machine.succeed("grep -F '${pkgs.procps}/bin/ps' /home/developer/.codex/ps-path")
    machine.succeed("kill -0 \"$(cat /home/developer/.codex/child.pid)\"")

    machine.succeed("systemctl stop codex-remote-control.service")
    machine.succeed("test -e /home/developer/.codex/stopped")
    machine.succeed("! kill -0 \"$(cat /home/developer/.codex/child.pid)\"")
  '';
}
