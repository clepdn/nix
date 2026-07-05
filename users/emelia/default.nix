{ pkgs, ... }:
{
  users.users.emelia = {
    isNormalUser = true;
    description = "Emelia";
    extraGroups = [];
    shell = pkgs.bash;
    hashedPassword = null;
    openssh.authorizedKeys.keys = [
    	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2sZUUtg/y3FKQsBUmNqH6SyJrvHKYLNCVlJdaJvH7t emelia@compilemaxxer" 
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQpK/dgOaRgax/GP5D/NvuIGWUy7ul6XRw9TQ4+WoT4 callie@madoka"
    ];
  };
}
