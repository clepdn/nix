{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.myNixOS.paseo;
  paseoServer = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    npmDepsHash = "sha256-i5PbVUe2Ec+GtghV9IpCJQJ9hcUT5hFhmxneNvoD584=";
  };
in
{
  imports = [ inputs.paseo.nixosModules.default ];

  options.myNixOS.paseo = {
    enable = lib.mkEnableOption "Paseo service";

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to run Paseo as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group to run Paseo as.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6767;
      description = "Port for Paseo to listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system}.desktop ];

    services.paseo = {
      enable = true;
      package = paseoServer;
      inherit (cfg) user group port;
      inheritUserEnvironment = true;
      listenAddress = "0.0.0.0";
      openFirewall = false;

      relay = {
        enable = false;
      };
    };
  };
}
