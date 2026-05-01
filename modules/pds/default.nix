{ config, lib, self, ... }:

let
  cfg = config.myNixOS.pds;
in
{
  options.myNixOS.pds = {
    enable = lib.mkEnableOption "AT Protocol Personal Data Server";

    hostname = lib.mkOption {
      type = lib.types.str;
      description = "Public hostname of the PDS (e.g. pds.example.com).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port the PDS listens on.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pds";
      description = "Directory to store PDS state and blobs.";
    };

    blobUploadLimit = lib.mkOption {
      type = lib.types.str;
      default = "104857600";
      description = "Size limit of uploaded blobs in bytes.";
    };

    inviteRequired = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether an invite code is required for registration.";
    };

    rateLimitsEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether rate limiting is enabled.";
    };

    plcUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://plc.directory";
      description = "URL of DID PLC directory.";
    };

    appViewUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://api.bsky.app";
      description = "URL of bsky frontend.";
    };

    appViewDid = lib.mkOption {
      type = lib.types.str;
      default = "did:web:api.bsky.app";
      description = "DID of bsky frontend.";
    };

    reportServiceUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://mod.bsky.app";
      description = "URL of mod service.";
    };

    reportServiceDid = lib.mkOption {
      type = lib.types.str;
      default = "did:plc:ar7c4by46qjdydhdevvrndac";
      description = "DID of mod service.";
    };

    crawlersUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://bsky.network";
      description = "URL of crawlers.";
    };

    secretFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the agenix-encrypted environment file with PDS_JWT_SECRET, PDS_ADMIN_PASSWORD, and PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX.";
    };

    enablePdsadmin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add pdsadmin CLI to PATH.";
    };

    enableGoat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Add goat ATProto CLI to PATH.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the PDS port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    age.secrets.pds = {
      file = cfg.secretFile;
      owner = "pds";
      group = "pds";
      mode = "400";
    };

    services.bluesky-pds = {
      enable = true;
      settings = {
        PDS_HOSTNAME = cfg.hostname;
        PDS_PORT = cfg.port;
        PDS_DATA_DIRECTORY = cfg.dataDir;
        PDS_BLOBSTORE_DISK_LOCATION = "${cfg.dataDir}/blocks";
        PDS_BLOB_UPLOAD_LIMIT = cfg.blobUploadLimit;
        PDS_INVITE_REQUIRED = lib.boolToString cfg.inviteRequired;
        PDS_RATE_LIMITS_ENABLED = lib.boolToString cfg.rateLimitsEnabled;
        PDS_DID_PLC_URL = cfg.plcUrl;
        PDS_BSKY_APP_VIEW_URL = cfg.appViewUrl;
        PDS_BSKY_APP_VIEW_DID = cfg.appViewDid;
        PDS_REPORT_SERVICE_URL = cfg.reportServiceUrl;
        PDS_REPORT_SERVICE_DID = cfg.reportServiceDid;
        PDS_CRAWLERS = cfg.crawlersUrl;
      };
      environmentFiles = [ config.age.secrets.pds.path ];
      pdsadmin.enable = cfg.enablePdsadmin;
      goat.enable = cfg.enableGoat;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
