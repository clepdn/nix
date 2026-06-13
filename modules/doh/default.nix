{ ... }:
{
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" ];
      ipv6_servers = true;
      server_names = [ "cloudflare" "cloudflare-ipv6" ];
      forwarding_rules = "/etc/dnscrypt-proxy/forwarding-rules.txt";
    };
  };

  # Forward MagicDNS queries to Tailscale's local resolver.
  # Everything else goes through dnscrypt-proxy → Cloudflare DoH.
  environment.etc."dnscrypt-proxy/forwarding-rules.txt".text = ''
    fox-pride.ts.net  100.100.100.100
  '';

  services.resolved = {
    enable = true;
    settings.Resolve.DNS = "127.0.0.1";
  };
}
