{ ... }:
let
  homura = "100.116.202.116";
  # Dovecot listens on this port for PROXY-wrapped IMAPS from us. Its
  # plain :993 stays tailnet-only and ignorant of PROXY protocol. Must
  # match the imaps_proxy port in modules/mail/default.nix.
  homuraImapsProxyPort = 9930;
in
{
  imports = [ ./vhost.nix ];

  # Public mail front for homura.
  # - :25  inbound mail from the wider internet
  # - :587 submission from MUAs; we proxy to homura's postfix, which auths
  #        the client and then relays out via comail
  # - :993 IMAPS from MUAs; we proxy to a *separate* port on homura whose
  #        listener expects PROXY (homura's plain :993 stays tailnet-only)
  #
  # `proxy_protocol on` makes nginx prepend a HAProxy v2 header so the
  # upstream sees the real remote IP. postfix/dovecot listeners are both
  # configured to expect this.
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
    server {
      listen      993;
      proxy_pass  ${homura}:${toString homuraImapsProxyPort};
      proxy_protocol on;
      proxy_timeout 30m;
      proxy_connect_timeout 30s;
    }
  '';

  networking.firewall.allowedTCPPorts = [ 25 587 993 ];
}
