{ pkgs, self, ... }:
{
  imports = [ "${self}/modules/services/codex-remote-control.nix" ];

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
