{ config, lib, pkgs, ... }:
let
  cfg = config.myNixOS.ttyd;
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
    containers.ttyd = {
      autoStart = true;
      privateNetwork = false;

      bindMounts."${stateDir}" = {
        hostPath = stateDir;
        isReadOnly = false;
      };

      config = { ... }: {
        services.ttyd = {
          enable = true;
          port = cfg.port;
          writeable = true;
          checkOrigin = true;
          maxClients = 3;
          entrypoint = [ "${stateDir}/my-bin" ];
        };

        networking.firewall.allowedTCPPorts = [ cfg.port ];
        system.stateVersion = "25.11";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${stateDir} 0750 root root -"
    ];

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
