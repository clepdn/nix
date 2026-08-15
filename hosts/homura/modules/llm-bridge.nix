{ config, ... }:
let keysFile = "/var/lib/llm-bridge/keys.json";
in
{
	services.llm-bridge = {
		enable = true;
		keysFile = keysFile;
		settings = {
			host = "0.0.0.0";
			port = 4040;
		};
	};


	systemd.tmpfiles.settings."llm-bridge"."${keysFile}".f = {
	    mode = "0600";
	    user = config.services.llm-bridge.user;
	    group = config.services.llm-bridge.group;
	    argument = "{}";
	};

	# Only allow access on tailscale for reverse proxy. Previously I thought this was sloppy. 
	# The problem is, this works. So... I'll leave it.
	networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 4040 ];
}
