{ config, self, ... }:
{
  age.secrets."home-assistant-secrets.yaml" = {
    file = "${self}/secrets/home-assistant-secrets.age";
    path = "/var/lib/hass/secrets.yaml";
    owner = "hass";
    group = "hass";
    mode = "400";
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      # onboarding
      "analytics" "google_translate" "met" "radio_browser" "shopping_list" "isal"
      # core components HA loads automatically
      "conversation" "assist_pipeline" "recorder" "frontend" "logbook" "history"
      "cloud" "mobile_app" "stream" "media_source"
      # integrations
      "tuya" "wyoming" "google_generative_ai_conversation" "piper"
      # light switches
      "netatmo" "lutron_caseta"
    ];
    config = {
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "100.77.12.60/32" ];
      };
    };
    configWritable = true;
    extraPackages = ps: with ps; [ hassil home-assistant-intents isal numpy pyturbojpeg ];
  };
}
