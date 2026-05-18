{
  imports = [
    ./computer.nix
    ./nematodes.nix
    ./pavement.nix
  ];

  security.acme = {
      acceptTerms = true;
      defaults.email = "calliepeden+acme@gmail.com";
  };
  
  services.nginx = {
    enable = true;
    streamConfig = ''
	server {
	    listen 25565;
	    proxy_pass 100.116.202.116:25565;
	    proxy_socket_keepalive on;
	    proxy_timeout 600m;
	    proxy_connect_timeout 60s;
	}
    '';
  };

  services.nginx.virtualHosts."_redirect" = {
    listen = [
      { addr = "0.0.0.0"; port = 80; }
      { addr = "[::]"; port = 80; }
    ];
    default = true;
    locations."/".return = "301 https://$host$request_uri";
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 443 25565 ];
  };
}
