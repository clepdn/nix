{ pkgs, ... }:
{
  # Make the deepfilternet LADSPA plugin discoverable via LADSPA_PATH.
  # pipewire's filter-graph LADSPA loader resolves plugin names against
  # LADSPA_PATH even when given an absolute path, so we have to register the
  # package here and reference the plugin by basename below.
  services.pipewire.extraLadspaPackages = [ pkgs.deepfilternet ];

  # Virtual noise-canceling microphone via DeepFilterNet's LADSPA plugin,
  # wired into the main pipewire daemon as a filter-chain drop-in.
  #
  # This creates a new "DeepFilter Noise Canceling Source" PipeWire source
  # that wraps the real mic and runs each capture frame through the
  # deep_filter_mono LADSPA filter. Pick that source as the input in
  # Discord/Zoom/whatever.
  #
  # Upstream reference:
  #   https://github.com/Rikorose/DeepFilterNet/blob/main/ladspa/filter-chain-configs/deepfilter-mono-source.conf
  # NOTE: drop-ins use *flat* top-level keys with literal dots
  # (e.g. "context.modules"), not nested objects. PipeWire merges
  # sections by top-level key name; a nested `{ context = { modules = ...; }; }`
  # would be treated as an unrelated section and silently ignored.
  services.pipewire.extraConfig.pipewire."99-deepfilter" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "DeepFilter Noise Canceling Source";
          "media.name"       = "DeepFilter Noise Canceling Source";
          "filter.graph" = {
            nodes = [
              {
                type   = "ladspa";
                name   = "DeepFilter Mono";
                plugin = "libdeep_filter_ladspa";
                label  = "deep_filter_mono";
                # 100 dB = no attenuation cap. Lower (e.g. 18–24) if the
                # filter is too aggressive and starts eating speech.
                control = {
                  "Attenuation Limit (dB)" = 100;
                };
              }
            ];
          };
          "audio.rate"     = 48000;
          "audio.channels" = 1;
          "audio.position" = [ "MONO" ];
          "capture.props" = {
            "node.name" = "capture.deepfilter-source";
            "node.passive" = true;
          };
          "playback.props" = {
            "node.name" = "deepfilter-source";
            "media.class" = "Audio/Source";
          };
        };
      }
    ];
  };
}
