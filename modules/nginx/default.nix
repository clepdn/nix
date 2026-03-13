{
  imports = [
    ./computer.nix
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

	upstream web {
	    server 127.0.0.1:8443;
	    server [::1]:8443;
	}

	upstream ssh {
	    server 127.0.0.1:22;
	}

	map $ssl_preread_protocol $protocol_upstream {
	    default ssh;
	    "TLSv1.2" web;
	    "TLSv1.3" web;
	}

	map $ssl_preread_server_name $name_upstream {
	    stlsprx.nematodes.net 127.0.0.1:20067;
	    default "";
	}

	map $name_upstream $upstream {
	    ""      $protocol_upstream;
	    default $name_upstream;
	}

	server {
	    listen 443;
	    listen [::]:443;
	    ssl_preread on;
	    proxy_pass $upstream;
	    proxy_timeout 60s;
	    proxy_responses 1;
	    error_log /var/log/nginx/stream.log;
	}
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 443 25565 ];
  };
}
