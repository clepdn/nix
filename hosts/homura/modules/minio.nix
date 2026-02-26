{ config, pkgs, self, ... }:
{
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
  
  age.secrets.tail = {
	file = "${self}/secrets/tailscale.age";
	owner = "tscl-minio";
	group = "tscl-minio";
	mode = "400";
  };

  users.users.tscl-minio = {
	isNormalUser = true;
	createHome = true;
	shell = pkgs.shadow; # /usr/bin/nologin for some reason
	group = "tscl-minio";
	description = "Tailscale user networking service user";
  };
  users.groups.tscl-minio = {};
  
  systemd.services.tscl-minio = {
  	enable = true;
	after = [ "network.target" ];
	wants = [ "network.target" ];
	wantedBy = [ "multi-user.target" ];
	serviceConfig = {
		Type = "simple";
		ExecStart = "${pkgs.tailscale}/bin/tailscaled --tun=userspace-networking --socket /home/tscl-minio/tailscaled-minio.sock";
		ExecStartPost = "${pkgs.tailscale}/bin/tailscale --socket /home/tscl-minio/tailscaled-minio.sock up --login-server=https://vpn.gaze.systems --auth-key=file:${config.age.secrets.tail.path}";
		Restart = "on-failure";
		RestartSec = "5s";
		User = "tscl-minio";
		Group = "tscl-minio";
	};
  };
}
