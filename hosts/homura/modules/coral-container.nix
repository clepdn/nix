# Declarative *envelope* for the `coral` nixos-container (which runs the `reef`
# config). Modeled on nano-container.nix.
#
# The whole trick is `path` instead of `config`. With `config`, the host builds
# the container's toplevel and bakes SYSTEM_PATH=<that host-built closure> into
# /etc/nixos-containers/coral.conf; the container's init is $SYSTEM_PATH/init,
# so any `nixos-rebuild switch` run *inside* the container survives only until
# the next container restart, then evaporates. Setting SYSTEM_PATH to the
# container's *own* system profile instead means it owns its own generations:
#
#   host  -> declaratively owns the envelope (network, autostart, bind mounts)
#   coral -> owns its config, via `nixos-rebuild switch --flake …#reef` inside
#            (and `nixos-container update coral` from the host still works too)
#
# The profile symlink is followed at each container start, so self-rebuilds and
# rollbacks stick across host `nixos-rebuild switch` — the host only ever
# touches the unit, never the closure.
#
# --- CRITICAL: `path` is the IN-CONTAINER view, not the host path ------------
# The nixos-containers unit bind-mounts the host's per-container profile dir
# onto /nix/var/nix/profiles *inside* the container:
#     --bind=/nix/var/nix/profiles/per-container/coral:/nix/var/nix/profiles
# and then execs "$SYSTEM_PATH/init". So from inside, the container's system is
# always at /nix/var/nix/profiles/system. Setting `path` to the HOST path
# (/nix/var/nix/profiles/per-container/coral/system) double-nests to
# .../per-container/coral/per-container/coral/system/init and fails to boot.
# Use the in-container path; the bind mount points it at gen N of the profile.
#
# --- Bootstrap (run once on homura, so the unit has something to start) -------
#   nix build /home/callie/code/nix#nixosConfigurations.reef.config.system.build.toplevel \
#     --profile /nix/var/nix/profiles/per-container/coral/system
#   # verify SYSTEM_PATH is the in-container profile path:
#   systemctl cat container@coral | grep SYSTEM_PATH   # -> /nix/var/nix/profiles/system
#
# --- Migration note -----------------------------------------------------------
# `coral` already exists imperatively (its /etc/nixos-containers/coral.conf is
# hand-written, AUTO_START=0). This module makes the host manage that conf
# declaratively and enables autostart. The existing rootfs at
# /var/lib/nixos-containers/coral and the per-container profile are reused in
# place, so no data is lost — but after the first switch, confirm:
#   nixos-container status coral
#
# --- Trade-off ----------------------------------------------------------------
# Because `path` bypasses module eval, the host cannot see inside the container,
# so anything crossing the boundary (forwardPorts, host-side firewall) must be
# kept in sync *here* by hand. Today the only ingress is coral's prometheus
# exporter on :9100, scraped by homura over the point-to-point veth. That port
# is opened by the container's own config (hosts/reef → allowedTCPPorts), and
# needs nothing on the host side because the veth is private to homura. If you
# ever expose a port to the wider tailnet, wire it here.
{ ... }:
{
  containers.coral = {
    autoStart      = true;
    privateNetwork = true;
    hostAddress    = "10.233.1.1";
    localAddress   = "10.233.1.2";

    # NOT `config`, and NOT the host per-container path. This is the container's
    # in-container view of its own system profile (see CRITICAL note above); the
    # unit bind-mounts the host's per-container/coral profile onto it, so the
    # container boots + self-rebuilds against its own generations.
    path = "/nix/var/nix/profiles/system";

    # ── Device passthrough (host-owned envelope) ─────────────────────────────
    # Expose both DRI devices: Intel iGPU (card1 / renderD128, pci 00:02.0) and
    # the discrete GPU (card2 / renderD129, pci 01:00.0). allowedDevices opens
    # the device cgroup (systemd DeviceAllow); the bind mount below makes the
    # nodes visible inside. renderD* are world-rw; card* are root:video, so a
    # process inside coral needs the `video` group to use card1/card2 (set that
    # in the reef config if you need display nodes, not just render/compute).
    allowedDevices = [
      { node = "/dev/dri/renderD128"; modifier = "rw"; }
      { node = "/dev/dri/renderD129"; modifier = "rw"; }
      { node = "/dev/dri/card1";      modifier = "rw"; }
      { node = "/dev/dri/card2";      modifier = "rw"; }
    ];

    # ── Bind mounts (host-owned envelope) ────────────────────────────────────
    bindMounts = {
      # GPU device nodes.
      "/dev/dri" = { hostPath = "/dev/dri"; isReadOnly = false; };

      # slskd state dir. slskd runs on homura (services.slskd, state in
      # /var/lib/slskd); this exposes it to coral.
      # NOTE: on the host it's 0770 slskd:slskd. privateUsers=no maps uids 1:1,
      # so coral's service user must share slskd's gid (or the perms must allow
      # it) to read/write — wire that group membership in the reef config if the
      # agent needs access, otherwise it'll see the mount but be denied.
      "/var/lib/slskd" = { hostPath = "/var/lib/slskd"; isReadOnly = false; };
    };
  };
}
