{ config, pkgs, lib, ... }:

let 
	cfg = config.services.qbit-container;
in
{
	options.services.qbit-container = {
		enable = lib.mkEnableOption "qBittorrent Container";

		libraryDir = lib.mkOption {
			type = lib.types.path;
			description = "Shared container library path";
		};

		qbitPort = lib.mkOption {
			type = lib.types.int;
			description = "Forwarded port for peers to connect to";
		};

		webuiPort = lib.mkOption {
			type = lib.types.int;
			description = "Port that the qBittorrent webui should listen on";
			default = 8080;
		};

		qbitgid = lib.mkOption {
			type = lib.types.int;
			description = "Group id for the qbittorrent service user";
			default = 1067;
		};
	
		wireguard = {
			presharedKeyFile = lib.mkOption {
				type = lib.types.path;
				description = "Wireguard pre-shared key";
			};

			privateKeyFile = lib.mkOption {
				type = lib.types.path;
				description = "Wireguard private key";
			};
		};

		fwdInterfaceName = lib.mkOption {
			type = lib.types.str;
			description = "Interface to port-forward container traffic on.";
		};

	};

	config = lib.mkIf cfg.enable {
		containers.qbittorrent = {
			autoStart = true;
			privateNetwork = true;
			hostAddress = "192.168.100.10";
			localAddress = "192.168.100.11";

			config = { config, pkgs, ... }: {
				networking = {
					wg-quick.interfaces.wg0 = {
						address = [ "10.147.64.105/32" "fd7d:76ee:e68f:a993:7674:a0a7:95c0:b24e/128" ];
						privateKeyFile = "/run/agenix/wireguard-privatekey";
						mtu = 1320;
						dns = [ "10.128.0.1" "fd7d:76ee:e68f:a993::1" ];

						peers = [
							{
								publicKey = "PyLCXAQT8KkM4T+dUsOQfn+Ub3pGxfGlxkIApuig+hk=";
								presharedKeyFile = "/run/agenix/wireguard-presharedkey";
								endpoint = "198.44.136.238:1637";
								allowedIPs = [ "10.147.64.105/32" "fd7d:76ee:e68f:a993:7674:a0a7:95c0:b24e/128" ];
								#allowedIPs = [ "0.0.0.0/0" "::/0" ];
								persistentKeepalive = 15;
							}
						];

					      postUp = ''
						ip route add 192.168.1.0/24 via 192.168.100.10
						ip route add 192.168.100.0/24 via 192.168.100.10
					      '';
					      
					      preDown = ''
						ip route del 192.168.1.0/24 || true
						ip route del 192.168.100.0/24 || true
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
					group = "qbit-library";
					serverConfig = {
						Preferences.WebUI.Address = "0.0.0.0";
						Preferences.WebUI.Port = toString cfg.webuiPort;
						Preferences.WebUI.Password_PBKDF2 = "@ByteArray(L2lxLViRgfULqaqyyrJFlg==:7Cd75WXRgMEx2328yhpApfk28+ZtzF6I1CcHKyDK6WfX+0KjM1D5bL+5Juzc1rqyxfHucnNo6I7g/SoFZzT+Fw==)";

						BitTorrent.Session.Interface = "wg0";
						BitTorrent.Session.InterfaceName= "wg0";
						BitTorrent.Session.Port = 29955;
						BitTorrent.Session.DefaultSavePath = "/run/library";
					};
				};
				
				users.groups.qbit-library = {
					gid = 1067;
				};

				system.stateVersion = "26.05";
			};

			bindMounts."/run/agenix/wireguard-privatekey" = {
				hostPath = cfg.wireguard.privateKeyFile;
			};
			bindMounts."/run/agenix/wireguard-presharedkey" = {
				hostPath = cfg.wireguard.presharedKeyFile;
			};
			bindMounts."/run/library" = {
				hostPath = "/mnt/hdd/library";
				isReadOnly = false;
			};
		  };

		  users.groups.qbit-library = {
			gid = 1067;	
		  };

		  # Open ports in the firewall.
		  networking.firewall.allowedTCPPorts = [
			cfg.webuiPort 
			cfg.qbitPort	
		  ];

		networking.firewall.extraForwardRules = ''
		  iifname "${cfg.fwdInterfaceName}" oifname "ve-qbittorrent" accept
		  iifname "ve-qbittorrent" oifname "${cfg.fwdInterfaceName}" ct state related,established accept
		'';

		  networking.nat = {
			enable = true;
			internalInterfaces = ["ve-qbittorrent"];
			externalInterface = "${cfg.fwdInterfaceName}";
			forwardPorts = [
				{
					destination = "192.168.100.11:${toString cfg.webuiPort}";
					sourcePort = cfg.webuiPort;
					proto = "tcp";
				}
				{
					destination = "192.168.100.11:${toString cfg.qbitPort}";
					sourcePort = cfg.webuiPort;
					proto = "tcp";
				}
			];
		  };

		
  		systemd.tmpfiles.rules = [
			"d /mnt/hdd/library 0775 1000 1067 -"
			#"d /mnt/hdd/library/* 0775 1000 1067 -" // edits '*'
		];
	};
}
