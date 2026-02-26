let
  mainCert = {
    # FIXME: This should be agenix.
    sslCertificate = "/etc/letsencrypt/live/on-her.computer/fullchain.pem";
    sslCertificateKey = "/etc/letsencrypt/live/on-her.computer/privkey.pem";
  };

  port8443 = [
    { addr = "[::]";   port = 8443; ssl = true; extraParameters = [ "http2" ]; }
    { addr = "0.0.0.0"; port = 8443; ssl = true; extraParameters = [ "http2" ]; }
  ];

  letsencryptOptions = ''
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
  '';

  commonProxyHeaders = ''
    proxy_pass_request_headers on;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $http_host;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $http_connection;
    proxy_buffering off;
  '';

  # Generates a simple reverse proxy vhost on port 8443
  proxyVhost = { target, extraLocationConfig ? "", extraVhostConfig ? "" }: mainCert // {
    listen = port8443;
    extraConfig = letsencryptOptions + extraVhostConfig;
    locations."/" = {
      proxyPass = target;
      extraConfig = commonProxyHeaders + extraLocationConfig;
    };
  };

  # Generates a pdsall-based vhost (no port 8443, uses snippet)
  # TODO: Redo this shit
  pdsVhost = { port, cert ? mainCert }: cert // {
    extraConfig = ''
      include /etc/nginx/snippets/pdsall.conf;
      # port ${toString port}
    '';
  };
in
{
  services.nginx = {
    enable = true;

    appendHttpConfig = ''
      # map $http_user_agent $blocked_user_agent { ... }
    '';

    virtualHosts = {
      "pds.on-her.computer"       = pdsVhost { port = 3000; };
      "*.pds.on-her.computer"     = pdsVhost { port = 3000; cert = {
        sslCertificate    = "/etc/letsencrypt/live/pds.on-her.computer/fullchain.pem";
        sslCertificateKey = "/etc/letsencrypt/live/pds.on-her.computer/privkey.pem";
      }; };
      "pegasus.on-her.computer"   = pdsVhost { port = 4000; };
      "*.pegasus.on-her.computer" = pdsVhost { port = 4000; cert = {
        sslCertificate    = "/etc/letsencrypt/live/pegasus.on-her.computer/fullchain.pem";
        sslCertificateKey = "/etc/letsencrypt/live/pegasus.on-her.computer/privkey.pem";
      }; };

      "cobalt.on-her.computer" = proxyVhost {
        target = "http://100.102.158.29:9000";
      };

      "book.on-her.computer" = proxyVhost {
        target = "http://100.116.202.116:6969";
        extraLocationConfig = "client_max_body_size 0;";
      };

      "auth.on-her.computer" = mainCert // {
        listen = port8443;
        extraConfig = letsencryptOptions + ''
          include /etc/nginx/snippets/authelia-authpage.conf;
        '';
      };
    };
  };
}

