{ ... }:
{
  imports = [ ./account.nix ];
  
  # For the switch.
  users.users.callie.extraGroups = [ "plugdev" ];
  users.groups.plugdev = {};

  home-manager.users.callie = import ./home.nix;
}
