{ config, lib, self, ... }:

let
  cfg = config.services.pds;
in
{
  options.services.pds = {
    enable = lib.mkEnableOption "Bluesky PDS container";

    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Public hostname of the PDS (e.g. pds.sluppy.moe).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Local port the PDS container listens on.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the environment file containing PDS secrets.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pds";
      description = "Host path for persistent PDS data.";
    };

    middleware = {
      address = lib.mkOption {
        type = lib.types.str;
        description = "Address of the middleware server to forward selected XRPC routes to.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        description = "Port of the middleware server.";
      };
      routes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "XRPC method names (e.g. com.atproto.repo.createRecord) to forward to the middleware instead of the PDS.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers.pds = {
        image = "ghcr.io/bluesky-social/pds:latest";
        environment = {
          PDS_HOSTNAME            = cfg.hostname;
          PDS_DATA_DIRECTORY      = "/pds";
          PDS_BLOBSTORE_DISK_LOCATION = "/pds/blocks";
          PDS_DID_PLC_URL         = "https://plc.directory";
          PDS_BSKY_APP_VIEW_URL   = "https://api.bsky.app";
          PDS_BSKY_APP_VIEW_DID   = "did:web:api.bsky.app";
          PDS_REPORT_SERVICE_URL  = "https://mod.bsky.app";
          PDS_REPORT_SERVICE_DID  = "did:plc:ar7c4by46qjdydhdevvrndac";
          PDS_CRAWLERS            = "https://bsky.network";
          PDS_PORT                = toString cfg.port;
        };
        environmentFiles = [ cfg.environmentFile ];
        volumes = [
          "${cfg.dataDir}:/pds:rw"
        ];
        ports = [
          "127.0.0.1:${toString cfg.port}:${toString cfg.port}"
        ];
        log-driver = "journald";
      };
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir}        0750 root root -"
      "d ${cfg.dataDir}/blocks 0750 root root -"
    ];
  };
}
