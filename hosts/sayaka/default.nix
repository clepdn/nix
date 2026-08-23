{ self, pkgs, ... }:
{
	imports = [
	      ./disko.nix
	      ./hardware-configuration.nix
	      "${self}/users/callie"
	      "${self}/users/emelia"
	      "${self}/modules/base"
	      "${self}/modules/tz/ny.nix"
	      "${self}/modules/nginx"
	      "${self}/modules/pds"
	      "${self}/modules/pavement"
	      "${self}/modules/computers.sex"
	];

	myNixOS.nix.homuraBuilder.enable = false;

	myNixOS.pavement = {
		enable = true;
		port = 3400;
	};

	myNixOS.pds = {
		enable = true;
		hostname = "pds2.on-her.computer";
		port = 3084;
		secretFile = "${self}/secrets/pds.env.age";
	};

	networking.hostName = "sayaka";
	users.mutableUsers = false;

	networking.networkmanager.ensureProfiles.profiles.enp1s0 = {
		connection = {
			id = "enp1s0";
			type = "ethernet";
			"interface-name" = "enp1s0";
			autoconnect-priority = 100;
		};
		ipv4 = {
			method = "manual";
			address1 = "178.156.177.25/32";
			gateway = "172.31.1.1";
			route1 = "172.31.1.1/32";
			dns = "1.1.1.1;8.8.8.8;";
		};
		ipv6 = {
			method = "manual";
			address1 = "2a01:4ff:f0:deca::1/64,fe80::1";
		};
	};

	# The provider routes the entire delegated /64 to this host.  Marking it
	# local lets wildcard listeners accept connections addressed to any member
	# of the subnet, not only the primary ::1 address.
	systemd.services.sayaka-ipv6-subnet = {
		description = "Accept Sayaka's delegated IPv6 subnet locally";
		wantedBy = [ "multi-user.target" ];
		wants = [ "network-online.target" ];
		after = [ "network-online.target" ];
		serviceConfig = {
			Type = "oneshot";
			RemainAfterExit = true;
			ExecStart = "${pkgs.iproute2}/bin/ip -6 route replace local 2a01:4ff:f0:deca::/64 dev lo";
			ExecStop = "-${pkgs.iproute2}/bin/ip -6 route del local 2a01:4ff:f0:deca::/64 dev lo";
		};
	};

	systemd.services.coredns = {
		requires = [ "sayaka-ipv6-subnet.service" ];
		after = [ "sayaka-ipv6-subnet.service" ];
	};

	services.coredns = {
		enable = true;
		config = ''
			small.foid.wang:53 {
				bind 178.156.177.25 2a01:4ff:f0:deca::1
				file /etc/coredns/small.foid.wang.zone
			}
		'';
	};

	systemd.services.coredns-tail = {
		description = "CoreDNS tailnet server";
		after = [ "network.target" "tailscaled.service" ];
		wantedBy = [ "multi-user.target" ];
		serviceConfig = {
			LimitNPROC = 512;
			LimitNOFILE = 1048576;
			CapabilityBoundingSet = "cap_net_bind_service";
			AmbientCapabilities = "cap_net_bind_service";
			NoNewPrivileges = true;
			DynamicUser = true;
			ExecStart = "${pkgs.coredns}/bin/coredns -conf=${pkgs.writeText "Corefile-tail" ''
				callie.moe:53 {
					bind 100.77.12.60
					file /etc/coredns/callie.moe.zone
				}

				. {
					bind 100.77.12.60
					forward . tls://1.1.1.1 tls://1.0.0.1 {
						tls_servername cloudflare-dns.com
					}
				}
			''}";
			ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR1 $MAINPID";
			Restart = "on-failure";
		};
	};

	environment.etc."coredns/small.foid.wang.zone".text = ''
$ORIGIN small.foid.wang.
$TTL 300
@ IN SOA ns-pub.callie.moe. hostmaster.small.foid.wang. (
  1
  3600
  600
  1209600
  300
)
@ IN NS ns-pub.callie.moe.
_atproto IN TXT "did=did:plc:madoka2bgqe6vudktdb7lzop"
'';

	environment.etc."coredns/callie.moe.zone".text = ''
$ORIGIN callie.moe.
$TTL 300
@ IN SOA tail-ns.callie.moe. hostmaster.callie.moe. (
  1
  3600
  600
  1209600
  300
)
@ IN NS tail-ns.callie.moe.
* IN A 100.77.12.60
* IN AAAA fd7a:115c:a1e0::4f37:c3c
'';


	services.tailscale.extraUpFlags = [ "--advertise-exit-node" ] ;

	boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

	boot.loader.grub.enable = true;
	
	networking.firewall.enable = true;
	networking.firewall.allowedTCPPorts = [ 53 2200 ];
	networking.firewall.allowedUDPPorts = [ 53 ];
	services.openssh.ports = [ 22 2200 ];

	system.stateVersion = "25.11";
}
