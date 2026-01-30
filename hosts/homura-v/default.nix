# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/gregtech
    ];

  nix.settings = {
	experimental-features = [ "nix-command" "flakes" ];
	trusted-users = [ "root" "callie" ];
  };

  fileSystems."/mnt/hdd" = {
	device = "/dev/disk/by-uuid/eafaf86c-1442-4512-91d2-28c63f79547b";
	fsType = "btrfs";
	options = [ "compress=zstd" ];
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "homura-v"; # like hyperv
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.gregtech.enable = true;

  services.xserver.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # I'm pretty sure I don't need this enabled. This is a seedbox.
  services.pulseaudio.enable = false;
  security.rtkit.enable = false;
  services.pipewire = {
    enable = false;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.callie = {
    isNormalUser = true;
    description = "Callie";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  programs.firefox.enable = true;
  programs.neovim.enable  = true;
  programs.fish.enable    = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
     vim
     wget
     git
     parted
     btrfs-progs
     rclone
     mosh
     #lemonade 
     kitty
     opencode
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Enable the OpenSSH daemon.
  services.openssh = {
	enable = true;
	settings = {
	PasswordAuthentication = false;
		KbdInteractiveAuthentication = false;
		PermitRootLogin = "prohibit-password";
	};
  };

  # rclone
  
  /*
  users.users.rclone-s3 = {
	isSystemUser = true;
	group = "s3";
	description = "rclone S3 bucket service user.";
  };

  systemd.services.rclone-s3 = {
	description = "rclone S3 host";
	after = [ "network.target" ];
	wantedBy = [ "multi-user.target" ];

	serviceConfig = {
		Type = "simple";
		User = "rclone-s3";
		ExecStart = "${pkgs.rclone}/bin/rclone serve s3 /mnt/hdd/s3 --addr :9000";
		Restart = "always";

		NoNewPrivileges = true;
		PrivateTmp = true;
		ProtectSystem = "strict";
		ProtectHome = true;
		ReadWritePaths = [ "/mnt/hdd/s3" ];
	};
  };
  */

  age.secrets.minio = {
	file = ../../secrets/minio.age;
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
	file = ../../secrets/tailscale.age;
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

  services.tailscale.enable = true;
  services.avahi.nssmdns4.enable = true;

  age.secrets.wg-key = {
	file = ../../secrets/muliphein.age;
	mode = "400";
	owner = "systemd-network";
  };
  age.secrets.wg-pskey = {
	file = ../../secrets/muliphein-pskey.age;
	mode = "400";
	owner = "systemd-network";
  };

  containers.qbittorrent = {
	autoStart = true;
	privateNetwork = true;
	hostAddress = "192.168.100.11";
	localAddress = "192.168.100.10";

	config = { config, pkgs, ... }: {
		
		networking = {
			wireguard.interfaces.wg0 = {
				ips = [ "10.147.64.105/32" "fd7d:76ee:e68f:a993:7674:a0a7:95c0:b24e/128" ];
				privateKeyFile = "/run/agenix/wireguard-privatekey";
				mtu = 1320;
				peers = [
					{
						publicKey = "pylcxaqt8kkm4t+dusoqfn+ub3pgxfglxkiapuig+hk=";
						presharedKeyFile = "/run/agenix/wireguard-presharedkey";
						endpoint = "198.44.136.238:1637";
						allowedIPs = [ "0.0.0.0/0" "::/0" ];
					}
				];
				postSetup = ''
				  ip route add 198.44.136.238 via 192.168.100.11 dev eth0
				'';
			};

			nameservers = [
				"10.128.0.1"
				"fd7d:76ee:e68f:a993::1"
			];
			
			firewall.enable = false;
		};

		#services.resolved.enable = true;
		
		services.qbittorrent = {
			enable = true;
			openFirewall = true;
			serverConfig = {
				#WebUI.Address = "0.0.0.0";
				#WebUI.Port = 8080;
				Preferences.WebUI.Password_PBKDF2 = "@ByteArray(L2lxLViRgfULqaqyyrJFlg==:7Cd75WXRgMEx2328yhpApfk28+ZtzF6I1CcHKyDK6WfX+0KjM1D5bL+5Juzc1rqyxfHucnNo6I7g/SoFZzT+Fw==)";

				BitTorrent.Session.Interface = "wg0";
				BitTorrent.Session.InterfaceName= "wg0";
				BitTorrent.Session.Port = 29955;
			};
		};

		environment.systemPackages = with pkgs; [
			traceroute
		];
	};

	bindMounts."/run/agenix/wireguard-privatekey" = {
		hostPath = config.age.secrets.wg-key.path;
	};
	bindMounts."/run/agenix/wireguard-presharedkey" = {
		hostPath = config.age.secrets.wg-pskey.path;
	};
  };

  /*systemd.services.qbit-fw = { # Stupid fucking socat port forward. I can't get NAT to work :(
	description = "Port forward to qbittorrent webui";
	after = [ "network.target" "container@qbittorrent.service" ];
	wantedBy = [ "multi-user.target" ];

	serviceConfig = {
		ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:8080,fork,reuseaddr TCP:192.168.100.11:8080";
		Restart = "always";
	};
  };*/

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
  	8080 # qbittorrent container
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  #networking.firewall.enable = false;

  networking.nat = {
	enable = true;
	internalInterfaces = ["ve-qbittorrent"];
	externalInterface = "eth0";
	forwardPorts = [
		{
			destination = "192.168.100.11:8080";
			sourcePort = 8080;
		}
	];
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
