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
      # pulls in assist_pipeline, bluetooth, cloud, conversation, dhcp, energy,
      # history, homeassistant_alerts, logbook, media_source, mobile_app, stream, etc.
      "default_config"
      "mobile_app"
      # onboarding & perf
      "analytics" "google_translate" "met" "radio_browser" "shopping_list" "isal"
      # still need these explicitly
      "recorder" "frontend"
      # integrations
      "tuya" "wyoming" "google_generative_ai_conversation" "piper"
      "netatmo" "lutron_caseta"
    ];
    config = {
      homeassistant = {
        external_url = "https://home.on-her.computer";
      };
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [ "100.77.12.60/32" ];
      };
    };
    configWritable = true;
    extraPackages = ps: with ps; [ hassil home-assistant-intents isal numpy pyturbojpeg ];
  };
}
