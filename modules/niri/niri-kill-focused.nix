{ pkgs, niri-unstable }:
pkgs.writeShellApplication {
  name = "niri-kill-focused";
  runtimeInputs = [
    niri-unstable
    pkgs.jq
    pkgs.gawk
    pkgs.coreutils
    pkgs.systemd
  ];
  text = ''
    pid=$(niri msg --json focused-window | jq -r '.pid // empty')
    if [[ -z "$pid" ]]; then
      exit 1
    fi

    # /proc/<pid>/cgroup's first line ends in the leaf cgroup path; the
    # final path component is the systemd unit the process belongs to.
    unit=$(basename "$(awk -F: 'NR==1{print $3}' /proc/"$pid"/cgroup)")

    # Only ever target app scopes (i.e. things launched via `uwsm app --`
    # or `systemd-run --user --scope`). Resolving to niri.service, the
    # user slice, or graphical-session.target would tear down the whole
    # session.
    case "$unit" in
      app-*.scope) ;;
      *)
        echo "niri-kill-focused: refusing to kill '$unit' (not an app-*.scope)" >&2
        exit 1
        ;;
    esac

    # SIGTERM first so the app can flush state; escalate to SIGKILL if
    # the scope is still alive after a short grace period.
    systemctl --user kill --signal=SIGTERM "$unit"
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      if ! systemctl --user is-active --quiet "$unit"; then
        exit 0
      fi
      sleep 0.2
    done
    systemctl --user kill --signal=SIGKILL "$unit"
  '';
}
