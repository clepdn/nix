{ ... }:
{
  nix.settings = {
	experimental-features = [ "nix-command" "flakes" ];
	trusted-users = [ "root" ];
  };

  nixpkgs.config.allowUnfree = true;
}
