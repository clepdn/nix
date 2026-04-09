{ config, self, ... }:
{
	age.secrets.slugtan = {
		file = "${self}/secrets/slugtan.env.age";
		owner = "bsky-bot";
		group = "bsky-bot";
		mode = "400";
	};
	services.slug-tan = {
		enable = true;
		envFile = config.age.secrets.slugtan.path;
	};
}
