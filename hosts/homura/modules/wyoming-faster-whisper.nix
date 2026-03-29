{ pkgs, ... }:
let
  ctranslate2-cuda = pkgs.ctranslate2.override { withCUDA = true; };

  python3 = pkgs.python3.override {
    packageOverrides = _: super: {
      ctranslate2 = super.ctranslate2.override {
        ctranslate2-cpp = ctranslate2-cuda;
      };
    };
  };

  wyoming-faster-whisper-cuda = pkgs.wyoming-faster-whisper.override {
    python3Packages = python3.pkgs;
  };
in
{
  services.wyoming.faster-whisper = {
    package = wyoming-faster-whisper-cuda;

    servers.main = {
      enable = true;
      model = "small-int8";
      language = "en";
      device = "cuda";
      uri = "tcp://0.0.0.0:10300";
    };
  };
}
