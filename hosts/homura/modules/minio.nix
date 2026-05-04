{ config, pkgs, self, ... }:
{
  nixpkgs.config.permittedInsecurePackages = [
    "minio-2025-10-15T17-29-55Z"
  ];
  age.secrets.minio = {
	file = "${self}/secrets/minio.age";
	owner = "minio";
	group = "minio";
	mode = "400";
  };

  services.minio = {
	enable = true;
	dataDir = [ "/mnt/hdd/s3" ];
	rootCredentialsFile = config.age.secrets.minio.path;
  };

  systemd.tmpfiles.rules = [
	"d /mnt/hdd/s3 0750 minio minio -"
	"d /var/lib/tscl-minio/ 0700 tscl-minio tscl-minio -"
  ];
  
  users.users.tscl-minio = {
	isNormalUser = true;
	createHome = true;
	shell = pkgs.shadow; # /usr/bin/nologin for some reason
	group = "tscl-minio";
	description = "Tailscale user networking service user";
  };
  users.groups.tscl-minio = {};
  
  # ---------------------------------------------------------------------
  # REMINDER: tscl-minio no longer auto-registers on start.
  #
  # tailscaled persists its node identity in
  #   /home/tscl-minio/.local/share/tailscale/tailscaled.state
  # so once the node is registered, restarts just resume the saved
  # identity. We do NOT pass a pre-auth key here, because the previous
  # ExecStartPost re-ran `tailscale up --auth-key=` on every restart and
  # bricked the service whenever the headscale pre-auth key expired (it
  # was set to 12h). See git history for that pain.
  #
  # If the state dir is ever wiped (or the node is logged out / expired
  # on headscale), re-register manually:
  #
  #   # 1. generate a fresh pre-auth key on the headscale host:
  #   #      headscale preauthkeys create --user <user> --reusable --expiration 90d
  #   # 2. then on homura:
  #   sudo -u tscl-minio \
  #     tailscale --socket /home/tscl-minio/tailscaled-minio.sock up \
  #       --login-server=https://vpn.klbr.net \
  #       --auth-key=<key>
  # ---------------------------------------------------------------------
  systemd.services.tscl-minio = {
  	enable = true;
	after = [ "network.target" ];
	wants = [ "network.target" ];
	wantedBy = [ "multi-user.target" ];
	serviceConfig = {
		Type = "simple";
		ExecStart = "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --socket /home/tscl-minio/tailscaled-minio.sock";
		Restart = "on-failure";
		RestartSec = "5s";
		User = "tscl-minio";
		Group = "tscl-minio";
	};
  };
}
