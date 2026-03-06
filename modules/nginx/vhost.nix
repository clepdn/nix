{ config, lib, ... }:
let cfg = config.myServices.acme;
  port8443 = [
    { addr = "[::]";   port = 8443; ssl = true; extraParameters = [ "http2" ]; }
    { addr = "0.0.0.0"; port = 8443; ssl = true; extraParameters = [ "http2" ]; }
  ];
in {
  options.myServices.acme = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options.port = lib.mkOption { type = lib.types.port; };
      optionts.target = lib.mkOption { type = lib.types.str; };
      options.dnsProvider = lib.mkOption { type = lib.types.str; };
      options.environmentFile = lib.mkOption { type = lib.types.str; };
      options.extraNginxOpts = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
      };
    });
    default = {};
  };

  config = {
    security.acme.certs = lib.mapAtrrs (name: opts: {
      domain = name;
      extraDomainNames = lib.removePrefix "*." name;
    }) cfg;

    services.nginx.virtualHosts = lib.mapAttrs (name: opts: {
      listen = port8443; # Listen on internal upstream proxied HTTP port. Eventually translated to 443 upstream.
      useACMEHost = name;
    } // opts.extraNginxOpts) cfg;
  };
}
