{ ... }:
{
  containers.nano-a = {
    autoStart      = true;
    privateNetwork = true;
    hostAddress = "10.233.1.1";
    localAddress = "10.233.1.40";
    path = "/nix/var/nix/profiles/per-container/nano/system";
  };
}
