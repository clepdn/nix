# Minecraft via nix-minecraft (https://github.com/Infinidoge/nix-minecraft).
# Fabric server with a vanilla-gameplay performance mod profile, including
# GPU-accelerated (OpenCL) chunk generation via the C2ME OpenCL addon.
# Console: tmux -S /run/minecraft/vanilla.sock attach (Ctrl+b d to detach).
# Note: the comfymc podman container already owns port 25565.
#
# Skipped (no MC 26.2 builds as of 2026-07): krypton, modernfix.
# C2ME base + OpenCL addon versions must stay paired (same devbuild).
{ pkgs, lib, inputs, ... }:
let
  mods = pkgs.linkFarmFromDrvs "mods" (builtins.attrValues {
    Fabric-API = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/P7dR8mSH/versions/Kr4WG5mG/fabric-api-0.154.2%2B26.2.jar";
      sha512 = "7cedad862e8105a7de8db090c0707c25a14a9472654090861dcf490f834862c3212723e762f6f797a0e4683104f4b3a20d3692fb29d7b5c0af437613283d34db";
    };
    Lithium = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/gvQqBUqZ/versions/vy3clWg7/lithium-fabric-0.25.1%2Bmc26.2.jar";
      sha512 = "165320d63464bf45676ff6b4437111e63547ac7f752d7b19a19cdf90083c4c941062ba82dd1dc80ba539a07a97dc08e7db81405fd3ac0998f2a374806d70651a";
    };
    FerriteCore = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/uXXizFIs/versions/d5ddUdiB/ferritecore-9.0.0-fabric.jar";
      sha512 = "d81fa97e11784c19d42f89c2f433831d007603dd7193cee45fa177e4a6a9c52b384b198586e04a0f7f63cd996fed713322578bde9a8db57e1188854ae5cbe584";
    };
    VeryManyPlayers = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/wnEe9KBa/versions/d6FfpWFI/vmp-fabric-mc26.2-0.2.0%2Bbeta.7.236-all.jar";
      sha512 = "2e0fd87e66f35f00f634176d4072a6c6d1eee965d1817833709ad3ea73e4f2719fa152d5e95b5ab8216b064c7db124b7f13838ebea87d92f7a72df82839e9bd5";
    };
    # Starlight-style lighting engine; also required by C2ME-OpenCL.
    ScalableLux = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/Ps1zyz6x/versions/Od3oPrei/ScalableLux-fabric-0.3.0-alpha.0.2-all.jar";
      sha512 = "8a3fc97b9c5c263e2858f38d31dd510afc919bdf65b91169bd0d5a1664db982129a98f773a1273d0e4b0763ddc2e889d19fbdf4921b5dcc456c046c3f90615f6";
    };
    NoChatReports = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/qQyHxfxd/versions/uiY9tUaj/NoChatReports-FABRIC-26.2-v2.20.1.jar";
      sha512 = "139dd09e04cc66fe4745264ddfbe3249be6e956326c931eb9707f9a640bbc011a4f1fd5684d04ca90e1b473be55772b0279e5c2f935c2f2e85d054e2ab0a6923";
    };
    Spark = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/l6YH9Als/versions/iYFOl6lQ/spark-1.10.173-fabric.jar";
      sha512 = "1dcbf2b76ceacf07523afaeaf63d3625b0318077cc6ce588bb701aea4a494bc2a5179fd2ca5aeda9513c6a2248c2ec590387e8aec6ac9fd8e3d01760bbc3dbfb";
    };
    #C2ME = pkgs.fetchurl {
    #  url = "https://cdn.modrinth.com/data/VSNURh3q/versions/sBKVreDD/c2me-fabric-mc26.2-0.4.2-alpha.0.12.jar";
    #  sha512 = "757eb369c94ca63b3297f30e2e561aff9c9b02aaaf9891fded7e60b97b6e981def556f226b0b272026f7ff90c550989efea21555d10d0fff7ac4de27a2fb66a5";
    #};
    # C2ME-OpenCL = pkgs.fetchurl {
    #   url = "https://cdn.modrinth.com/data/qtPMklut/versions/qthAcnhZ/c2me-fabric-opts-accel-opencl-mc26.2-0.4.2-alpha.0.12.jar";
    #   sha512 = "06f671bcea76342802b296be1ef823c4abd86abd2dba7f2ca7c40482a023e1dfb1420d8d0a47cd350472640e8676d9d31b7229d0b09257852f480781e08891d1";
    # };
    ViaFabric = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/YlKdE5VK/versions/rRHSH3qm/ViaFabric-0.4.21%2B172-26.x.jar";
      sha512 = "a7a221a80ad283ff58fc84167b98f2628d1800efcf218f79d9de670d28e31fe255bfb43c97caf295c0e84b096bafa6617184168b2dd444385026ca75884a1579";
    };
    ViaBackwards = pkgs.fetchurl {
      url = "https://cdn.modrinth.com/data/NpvuJQoq/versions/YjpKsm6j/ViaBackwards-5.10.0.jar";
      sha512 = "a301113283ff8dacb5f2ac4c45632b37ade79563689ee342c9e74bce16a5c805d72ec641b05f86fd772558312860f92f5fd52ae246cc28762534a4bed794beaa";
    };
  });
in
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];

  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  # NVIDIA OpenCL needs nvidia_uvm; don't rely on something else loading it.
  boot.kernelModules = [ "nvidia_uvm" ];

  networking.firewall.allowedTCPPorts = [ 25566 ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;

    servers.vanilla = {
      enable = true;
      # Pin the MC version so the mod jars above stay paired with the server.
      # MC 26.2 requires Java 25; nix-minecraft's fabric wrapper defaults to
      # jre_headless (Java 21 in nixpkgs), so override it here.
      package = pkgs.fabricServers.fabric-26_2.override {
        jre_headless = pkgs.jdk25_headless;
      };
      jvmOpts = "-Xms2G -Xmx8G";

      symlinks."mods" = mods;

      # OpenCL loader for c2me-ocl. nixpkgs' ocl-icd is patched to look in
      # /run/opengl-driver/etc/OpenCL/vendors, where the nvidia ICD lives.
      environment = {
        LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.ocl-icd ];
        OCL_ICD_VENDORS = "/run/opengl-driver/etc/OpenCL/vendors";
      };

      serverProperties = {
        server-port = 1629;
        motd = "§fbrickhons§r §l§n§4ONLY";
        difficulty = "normal";
        view-distance = 20;
        spawn-protection = 0;
      };
    };
  };

  # Relax nix-minecraft's hardening just enough for GPU (OpenCL) access.
  systemd.services.minecraft-server-vanilla.serviceConfig = {
    PrivateDevices = lib.mkForce false;
    DeviceAllow = lib.mkForce [
      # Class names as listed in /proc/devices on homura.
      "char-nvidia rw" # /dev/nvidia0
      "char-nvidiactl rw" # /dev/nvidiactl
      "char-nvidia-uvm rw" # /dev/nvidia-uvm, /dev/nvidia-uvm-tools
    ];
  };
}
