{ config, pkgs, ... }:
{
  services.llama-cpp = {
    enable = true;
    model = "/var/lib/llama/gemma4-e4b.gguf";
    port = 8020;
    extraFlags = [ "--api-key" "e3db5bbc-efb8-4934-b0b0-e386d4139c78" ];
    package = pkgs.llama-cpp.override { cudaSupport = true; };
  };
}
