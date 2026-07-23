{ pkgs, ... }:
{
  hardware.i2c.enable = true;
  users.users.callie.extraGroups = [ "i2c" ]; # Terrible, I know. I don't care.
  environment.systemPackages = with pkgs; [ ddcutil ddcui ];
}
