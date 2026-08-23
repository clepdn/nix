{ pkgs, self, ... }:
{
  imports = [ "${self}/modules/services/codex-remote-control.nix" ];

  systemd.user.tmpfiles.rules = [
    "d %h/.codex/packages/standalone/current 0755 - - -"
    "L+ %h/.codex/packages/standalone/current/codex - - - - /nix/store/vy5ww88zmkwffaqvqb9hv0zvd9p1nc7h-codex-0.147.0/bin/codex"
  ];

  services.codexRemoteControl = {
    enable = true;
    package = pkgs.codex;
    user = "callie";
    codexHome = "/home/callie/.codex";
    workingDirectory = "/home/callie";

    extraPackages = with pkgs; [
      bashInteractive
      coreutils
      findutils
      git
      gnugrep
      gnused
      nix
      openssh
      ripgrep
    ];
  };
}
