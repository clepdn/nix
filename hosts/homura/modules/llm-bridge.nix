{ config, self, ... }:
{
	age.secrets.umansKey = {
		file  = "${self}/secrets/umans-api-key.age";
		mode  = "0400";
		owner = config.services.llm_bridge.user;
	};

	services.llm_bridge = {
		enabled = true;
		host = "0.0.0.0";
		port = 4040;

		keysFile = config.age.secrets.umansKey.path;

		providers.umans = {
			api_key_file = config.age.secrets.llm_bridge.path;
			base_url = "https://api.code.umans.ai/v1";
		};
	};
}
