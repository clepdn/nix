{ config, self, ... }:
{
	age.secrets.umansKey = {
		file  = "${self}/secrets/umans-api-key.age";
		mode  = "0400";
		owner = config.services.llm-bridge.user;
	};

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

			providers.umans = {
				api_key_file = config.age.secrets.umansKey.path;
				base_url = "https://api.code.umans.ai/v1";
			};
		};
	};

	# Reached by sayaka's nginx (bridget.on-her.computer) over the tailnet only.
	# Not opened publicly — external clients go through nginx TLS on sayaka.
	networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 4040 ];
}
