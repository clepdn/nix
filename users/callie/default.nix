{ ... }:
{
  imports = [ ./account.nix ];

  users.users.callie.extraGroups = [ "plugdev" ];

  home-manager.users.callie = import ./home.nix;
}
