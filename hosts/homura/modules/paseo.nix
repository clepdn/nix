{ self, ... }:
{
  imports = [ "${self}/modules/paseo" ];

  myNixOS.paseo = {
    enable = true;
    user = "callie";
  };
}
