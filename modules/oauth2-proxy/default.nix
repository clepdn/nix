{ config, self, ... }:

{
  # Format of oauth2-proxy.age:
  #   OAUTH2_PROXY_CLIENT_SECRET=<client secret registered in dex>
  #   OAUTH2_PROXY_COOKIE_SECRET=<random 32-byte base64 string>
  age.secrets.oauth2-proxy = {
    file = "${self}/secrets/oauth2-proxy.age";
    owner = "oauth2-proxy";
    group = "oauth2-proxy";
    mode = "400";
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    clientID = "oauth2-proxy";
    oidcIssuerUrl = "https://dex.on-her.computer";
    redirectURL = "https://auth.on-her.computer/oauth2/callback";
    httpAddress = "http://0.0.0.0:4180";
    keyFile = config.age.secrets.oauth2-proxy.path;
    setXauthrequest = true;
    reverseProxy = true;
    email.domains = [ "*" ];
    cookie = {
      secure = true;
      domain = ".on-her.computer";
    };
    extraConfig = {
      skip-provider-button = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 4180 ];
}
