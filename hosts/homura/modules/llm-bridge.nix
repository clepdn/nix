{ config, self, ... }:
{
	age.secrets.bridgeKeys = {
		file  = "${self}/secrets/bridge-keys.json.age";
		mode  = "0400";
		owner = config.services.llm-bridge.user;
	};

	services.llm-bridge = {
		enable = true;

		keysFile = config.age.secrets.bridgeKeys.path;

		settings = {
			host = "0.0.0.0";
			port = 4040;
		};
	};

	# Reached by sayaka's nginx (bridget.on-her.computer) over the tailnet only.
	# Not opened publicly — external clients go through nginx TLS on sayaka.
	networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 4040 ];
}
