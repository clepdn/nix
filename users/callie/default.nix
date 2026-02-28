{ config, pkgs, lib, inputs, ... }:
{
  users.users.callie = {
    isNormalUser = true;
    description = "Callie";
    extraGroups = [ "networkmanager" "wheel" "input" "video" ];
    shell = pkgs.fish;
    hashedPassword = "$y$j9T$ZJuNNt8D4FZIqVGqytHP31$tE9z6v5nFb7XSUzFKcqEmKlidCjhhRyLDx.WJh9gD.6";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDQpK/dgOaRgax/GP5D/NvuIGWUy7ul6XRw9TQ4+WoT4"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF15zfSwLqQhjQYs6SKxHfCYdeyDkDx9ODRIrnGiXx5E"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6hUWuV72dWU5P6MkmAKDbKsimS8sOL+D/Dm+2FxVXJ"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDW+PiZspzE9wNSCleUfEiZv102HPzcq+wxlkCzliWUEbswtWAlHVV+Mn+FPvb0jC/XrOMgFhSdGXpP0100fGD7A2WlksPkN5FV2eIq1gxlqsDF3ItEi8mqw5kX2THM6UirXFIq9bdlj33sU6nFz50zPy6Uc4NGdEZ103x5+XSAZeXR6dpdWgwOgtdKZvgV3ZX7ACvDZ1abj7UdErM4kGBZDIG4xSS1m6BgyAay4zMj8sVYKphjLXawZUZfhns/jaWxJzPAZYW5hzlTgXae33yX/wXWdlzM9i9KVnMhbaF8WCH8jvlGSFVqhlY4kSPQ8LjX3DT7Qs/awrRS8DQjk1MK6/WgP6rC/d9w+hl14yelWYY2POFkbccKhL8oaIvZd48MLa8oDWDm5bDLV/ihmBVL1DLfABAgvNqNqJLDiyIf9BcphXGuzuRnxKLHi+1wxlSRtwpgDEGsy10/kQDuv+JuKgkCarWwWGBskFzGEj2ejjKB1fM9Aue/yphzPyUMDrc="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICfb1KhR8p1qNp33GLdVOm2kgah/O8/fn6Lg1RW1BVpL"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFexR51gVO+v5+mW6roktsex5Im2vxVPlD82Cgd0PxMv"
    ];
    packages = with pkgs; [
      kdePackages.kate
      inputs.zen-browser.packages."${pkgs.system}".default
      qdirstat
      feishin
      thunderbird
    ];
  };

  home-manager.users.callie = { pkgs, ... }: {
    home = {
      homeDirectory = config.users.users.callie.home;
      # packages =
      packages = [
      ];
      stateVersion = "25.11";
     };
  };

  programs.fish.enable = true;

  nix.settings.trusted-users = [ "callie" ];
}
