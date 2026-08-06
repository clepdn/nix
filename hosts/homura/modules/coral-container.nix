{ lib, ... }:
let devices = [ 
  "/dev/nvidia0" 
  "/dev/nvidiactl" 
  "/dev/nvidia-modeset" 
  "/dev/nvidia-uvm"  # CUDA (torch/transformers)
  "/dev/nvidia-uvm-tools"
];
in
{
  containers.coral = {
    autoStart      = true;
    privateNetwork = true;
    hostAddress    = "10.233.1.1";
    localAddress   = "10.233.1.2";

    path = "/nix/var/nix/profiles/system";

    allowedDevices = (map (node: {
      inherit node;
      modifier = "rw";
    }) devices) ++ [
      { node = "/dev/dri/renderD129";   modifier = "rw"; }  # NVIDIA render node
      { node = "/dev/dri/renderD128";   modifier = "rw"; }  # Intel render node (headless compositor)
    ];

    bindMounts = lib.genAttrs devices (path: {
      hostPath = path;
      isReadOnly = false;
    }) // 
    {
      "/dev/dri" = { hostPath = "/dev/dri"; isReadOnly = false; };

      "/run/opengl-driver" = { hostPath = "/run/opengl-driver"; isReadOnly = true; };

      "/var/lib/slskd" = { hostPath = "/var/lib/slskd"; isReadOnly = false; };
    };
  };
}
