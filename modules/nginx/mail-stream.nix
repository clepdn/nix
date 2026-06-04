{ ... }:
let
  homura = "100.116.202.116";
in
{
  imports = [ ./vhost.nix ];

  # Public mail front for homura.
  # - :25 takes mail from the wider internet.
  # - :587 takes submission from MUAs (clients send through us, we relay
  #        to comail with the shared SASL credentials).
  # IMAP (:143/:993) is intentionally NOT proxied; clients reach dovecot
  # directly over the tailnet.
  #
  # `proxy_protocol on` makes nginx prepend a HAProxy v2 header so postfix
  # sees the real remote IP. Both ports require this; postfix's listener
  # is configured with smtpd_upstream_proxy_protocol=haproxy.
  services.nginx.streamConfig = ''
    server {
      listen      25;
      proxy_pass  ${homura}:25;
      proxy_protocol on;
      proxy_timeout 10m;
      proxy_connect_timeout 30s;
    }
    server {
      listen      587;
      proxy_pass  ${homura}:587;
      proxy_protocol on;
      proxy_timeout 10m;
      proxy_connect_timeout 30s;
    }
  '';

  networking.firewall.allowedTCPPorts = [ 25 587 ];
}
