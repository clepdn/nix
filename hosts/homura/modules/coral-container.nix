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

    # ── GPU passthrough: NVIDIA dGPU (card2) ─────────────────────────────────
    # card2 = NVIDIA dGPU (pci 01:00.0, driver 580, `open=false`) — the GPU that
    # drives homura's display (DP-4). card1 is the idle Intel iGPU (i915, no
    # displays connected). "Wire to card2" = give coral the NVIDIA stack.
    #
    # NVIDIA is NOT the plain DRI model: compute/render go through the
    # /dev/nvidia* char nodes (all world-rw, so no group needed — DeviceAllow
    # gates the cgroup, the binds make them visible) plus the matching userspace
    # driver at /run/opengl-driver. renderD129 is card2's DRM render node (GBM/
    # prime interop); renderD128 (Intel) is exposed too as the cheap, zero-
    # contention render node for a *headless* compositor (see hosts/reef).
    #
    # Deliberately NO card* primary nodes and NO CAP_SYS_ADMIN: coral must not do
    # KMS. homura's niri already holds DRM master on card2, so any compositor in
    # here is headless — it never calls drmSetMaster.
    allowedDevices = [
      { node = "/dev/nvidia0";          modifier = "rw"; }
      { node = "/dev/nvidiactl";        modifier = "rw"; }
      { node = "/dev/nvidia-modeset";   modifier = "rw"; }
      { node = "/dev/nvidia-uvm";       modifier = "rw"; }  # CUDA (torch/transformers)
      { node = "/dev/nvidia-uvm-tools"; modifier = "rw"; }
      { node = "/dev/dri/renderD129";   modifier = "rw"; }  # NVIDIA render node
      { node = "/dev/dri/renderD128";   modifier = "rw"; }  # Intel render node (headless compositor)
    ];

    # ── Bind mounts (host-owned envelope) ────────────────────────────────────
    bindMounts = {
      # NVIDIA device nodes (compute + EGL/GBM).
      "/dev/nvidia0"          = { hostPath = "/dev/nvidia0";          isReadOnly = false; };
      "/dev/nvidiactl"        = { hostPath = "/dev/nvidiactl";        isReadOnly = false; };
      "/dev/nvidia-modeset"   = { hostPath = "/dev/nvidia-modeset";   isReadOnly = false; };
      "/dev/nvidia-uvm"       = { hostPath = "/dev/nvidia-uvm";       isReadOnly = false; };
      "/dev/nvidia-uvm-tools" = { hostPath = "/dev/nvidia-uvm-tools"; isReadOnly = false; };

      # DRI render nodes (NVIDIA renderD129 + Intel renderD128). The whole dir
      # is bound for visibility; DeviceAllow above restricts actual access to
      # the two render nodes (the root:video card* KMS nodes stay blocked).
      "/dev/dri" = { hostPath = "/dev/dri"; isReadOnly = false; };

      # Host GPU userspace driver, matched to the running kernel module (580).
      # nspawn shares the host kernel, so binding the host's /run/opengl-driver
      # guarantees the userspace↔kmod version match (libcuda, libGL, libEGL).
      # Re-resolved at each container start, so it tracks host driver updates.
      "/run/opengl-driver" = { hostPath = "/run/opengl-driver"; isReadOnly = true; };

      # slskd state dir. slskd runs on homura (services.slskd, state in
      # /var/lib/slskd); this exposes it to coral. On the host it's 0770
      # slskd:slskd (gid 962); privateUsers=no maps gids 1:1, so coral joins
      # that group in hosts/reef to read/write it.
      "/var/lib/slskd" = { hostPath = "/var/lib/slskd"; isReadOnly = false; };
    };
  };
}
