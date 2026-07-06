{ self, config, lib, ... }:
let
  cfg = config.myNixOS.nix.signing;

  # Every host with a known signing key. Their public halves are trusted
  # everywhere so any of them can push closures to any other host.
  signers = [ "madoka" "homura" "megatron" "reef" ];

  readPubkey = host:
    lib.removeSuffix "\n"
      (builtins.readFile "${self}/secrets/publicKeys/nix-signing-${host}.pub");
in {
  options.myNixOS.nix.signing = {
    enable = lib.mkEnableOption ''
      Local nix store signing. When enabled the host owns a signing key
      (from agenix) and stamps every path it builds, so unprivileged users
      can nix-copy-closure to any host that trusts the corresponding pubkey
      — no trusted-users escalation required.
    '';

    host = lib.mkOption {
      type = lib.types.enum signers;
      default = config.networking.hostName;
      description = ''
        Which signing key this host uses. Must match a
        secrets/nix-signing-<host>.age file.
      '';
    };
  };

  config = lib.mkMerge [
    {
      # Every host trusts every signer's pubkey.
      nix.settings.trusted-public-keys = map readPubkey signers;
    }
    (lib.mkIf cfg.enable {
      age.secrets."nix-signing-${cfg.host}" = {
        file = "${self}/secrets/nix-signing-${cfg.host}.age";
        mode = "0400";
        owner = "root";
        group = "root";
      };

      nix.settings.secret-key-files = [
        config.age.secrets."nix-signing-${cfg.host}".path
      ];
    })
  ];
}
