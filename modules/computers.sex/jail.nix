{ lib, pkgs,... }:
let 
  mkJailedUser = { name, sshKeys ? [] }: {
    users.users.${name} = {
      isNormalUser = true;
      group = "jailed";
      shell = "${pkgs.shadow}/bin/nologin";
      openssh.authorizedKeys.keys = sshKeys;
      home = "/var/www/computers.sex/";
      createHome = false;
      homeMode = "755";
    };

    systemd.tmpfiles.rules = [
      # Each home readable by group jailed? So that everyone can just,,, write shit? IDK mane
      "d /var/www/computers.sex/${name} 0775 ${name} jailed -"
    ];
  };
  userConfigs = 
    map mkJailedUser [ 
      {
        name = "jailtest";
        sshKeys = [
	  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQpK/dgOaRgax/GP5D/NvuIGWUy7ul6XRw9TQ4+WoT4 callie@madoka"
        ];
      }
  ];
  extraConfig = {
    services.openssh = {
      enable = true;
      extraConfig = ''
        Match group jailed
          ChrootDirectory /var/www/computers.sex
          ForceCommand internal-sftp
          AllowTcpForwarding no
          X11Forwarding no
          PasswordAuthentication no
      '';
    };

    users.groups.jailed = {};
  };

in {
  config = lib.mkMerge (userConfigs ++ [ extraConfig ] ); 
}
