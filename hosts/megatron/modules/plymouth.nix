{ self, pkgs, ... }:
{
  imports = [
    "${self}/modules/plymouth"
  ];
  boot.plymouth = {
    theme = "";
  };
}
