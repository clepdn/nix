{ lib, pkgs,... }:
let 
  mkJailedUser = { name, sshKeys ? [] }: {
    users.users.${name} = {
      isNormalUser = true;
      group = "jailed";
      shell = "${pkgs.shadow}/bin/nologin";
      openssh.authorized.keys = sshKeys;
      home = "/var/www/computers.sex/";
    };

    systemd.tmpfiles.rules = [
      # Each home readable by group jailed? So that everyone can just,,, write shit? IDK mane
      "d /var/www/computers.sex/${name} 0775 ${name} jailed -"
    ];
  };
  userConfigs = 
    map mkJailedUser [ 
      { 
        name = "emelia"; 
        sshKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2sZUUtg/y3FKQsBUmNqH6SyJrvHKYLNCVlJdaJvH7t emelia@compilemaxxer" 
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQpK/dgOaRgax/GP5D/NvuIGWUy7ul6XRw9TQ4+WoT4 callie@madoka"
        ];
      } 
  ];
  extraConfig = {
    imports = [ 
      ./nginx.nix
    ];

    services.openssh = {
      enable = true;
      extraConfig = ''
        Match group jailed
          ChrootDirectory /srv/sftp/%u
          ForceCommand internal-sftp
          AllowTcpForwarding no
          X11Forwarding no
          PasswordAuthentication no
      '';
    };

    users.groups.jailed = {};

    systemd.tmpfiles.rules = [
      "d /var/www/computers.sex 0755 root root - "
    ];
  };

in {
  config = lib.mkMerge (userConfigs ++ [ extraConfig ] ); 
}
