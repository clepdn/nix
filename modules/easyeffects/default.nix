# EasyEffects (per-user, callie) — applies oratory1990's parametric EQ for the
# HIFIMAN Sundara to the Moondrop DAWN PRO2 USB DAC.
#
# The DAWN PRO2 is a portable USB dongle, so this module is imported on every
# host callie plugs it into (megatron, madoka, deck). Its PipeWire node name is
# derived from the dongle's USB serial, so the autoload profile below matches on
# whichever machine the DAC is currently connected to.
#
# EQ values are oratory1990's measurements as published via AutoEq:
#   https://github.com/jaakkopasanen/AutoEq
#   results/oratory1990/over-ear/HIFIMAN Sundara (post-2020 earpads)
# (post-2020 earpads = the current-production open-back Sundara).
#
# EasyEffects 8 (Qt) reads presets from $XDG_DATA_HOME/easyeffects. The
# home-manager `services.easyeffects.extraPresets` option writes the preset to
# ~/.local/share/easyeffects/output/<name>.json and runs the daemon as a user
# service. To bind the preset to one specific output device we also drop an
# "autoload" profile keyed by the device's PipeWire node name + output route;
# EasyEffects then loads this preset automatically whenever the DAWN PRO2 is the
# active output (and leaves other outputs untouched).
{ lib, ... }:
let
  presetName = "oratory1990-sundara";

  # DAWN PRO2 "Analog Stereo" output, as reported by PipeWire (wpctl inspect /
  # pw-dump). The node name embeds this dongle's USB serial and is identical on
  # any host it's plugged into.
  device = "alsa_output.usb-MOONDROP_DAWN_PRO2_35D8011D251117-01.analog-stereo";
  deviceDescription = "DAWN PRO2 Analog Stereo";
  route = "Analog Output";

  # oratory1990 parametric EQ, HIFIMAN Sundara (post-2020 earpads).
  # oratory1990 filter type -> EasyEffects band type: LSC -> Lo-shelf,
  # PK -> Bell, HSC -> Hi-shelf.
  preamp = -6.6; # dB; applied as the equalizer input gain to avoid clipping
  bands = [
    { type = "Lo-shelf"; frequency = 105.0;   gain = 8.9;  q = 0.7; }
    { type = "Bell";     frequency = 56.0;    gain = -4.5; q = 0.4; }
    { type = "Bell";     frequency = 971.0;   gain = -1.8; q = 1.62; }
    { type = "Bell";     frequency = 2115.0;  gain = 2.1;  q = 2.21; }
    { type = "Bell";     frequency = 8270.0;  gain = 1.4;  q = 0.96; }
    { type = "Hi-shelf"; frequency = 10000.0; gain = -3.1; q = 0.7; }
    { type = "Bell";     frequency = 246.0;   gain = -0.6; q = 1.21; }
    { type = "Bell";     frequency = 128.0;   gain = 0.7;  q = 1.44; }
    { type = "Bell";     frequency = 59.0;    gain = -0.6; q = 2.26; }
    { type = "Bell";     frequency = 35.0;    gain = 0.2;  q = 1.56; }
  ];

  mkBand = b: {
    inherit (b) type gain frequency q;
    mode = "RLC (BT)";
    slope = "x1";
    solo = false;
    mute = false;
    width = 4.0;
  };

  # EasyEffects stores bands per-channel; keep left == right (no channel split).
  channel = builtins.listToAttrs (
    lib.imap0 (i: b: lib.nameValuePair "band${toString i}" (mkBand b)) bands
  );
in
{
  home-manager.users.callie = {
    services.easyeffects = {
      enable = true;

      extraPresets.${presetName}.output = {
        blocklist = [ ];
        plugins_order = [ "equalizer#0" ];
        "equalizer#0" = {
          bypass = false;
          "input-gain" = preamp;
          "output-gain" = 0.0;
          mode = "IIR";
          "split-channels" = false;
          balance = 0.0;
          "pitch-left" = 0.0;
          "pitch-right" = 0.0;
          "num-bands" = builtins.length bands;
          left = channel;
          right = channel;
        };
      };
    };

    # Autoload profile: filename must be "<node.name>:<route>.json".
    xdg.dataFile."easyeffects/autoload/output/${device}:${route}.json".text =
      builtins.toJSON {
        inherit device;
        "device-description" = deviceDescription;
        "device-profile" = route;
        "preset-name" = presetName;
      };
  };
}
