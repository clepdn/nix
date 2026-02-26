{ config, lib, self, ... }:
{
  imports = [
    ../locale.nix
  ];

  # Set your time zone.
  time.timeZone = "America/New_York";
}
