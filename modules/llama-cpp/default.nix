{ config, lib, pkgs, inputs, ... }:
let
  servicePort = 8020;
  pkg = (pkgs.llama-cpp.override { cudaSupport = true; }).overrideAttrs (old: {
    src = inputs.llama-cpp-src;
    version = "0";
    npmDepsHash = "sha256-RAFtsbBGBjteCt5yXhrmHL39rIDJMCFBETgzId2eRRk=";
    postPatch = "rm -f tools/server/public/index.html.gz";
    cmakeFlags = (old.cmakeFlags or []) ++ ["-DCMAKE_CUDA_ARCHITECTURES=61" "-DGGML_CUDA_FA=OFF"];
  });
in {
  age.secrets.llama-api-key = {
    file = ../../secrets/llama-api-key.age;
    mode = "0444";
  };

  services.llama-cpp = {
    enable = true;
    model = "/var/lib/llama/gemma4-e2b.gguf";
    port = servicePort;
    package = pkg;
  };

  systemd.services.llama-cpp.serviceConfig.ExecStart = lib.mkForce (
    pkgs.writeShellScript "llama-cpp-start" ''
      exec ${pkg}/bin/llama-server \
        --host 0.0.0.0 \
        --port ${toString servicePort} \
        -m ${config.services.llama-cpp.model} \
        --api-key "$(< ${config.age.secrets.llama-api-key.path})"
    ''

    #--mtp-head /var/lib/llama/gemma4-e2b-mtp.gguf
  );

  networking.firewall.allowedTCPPorts = [ servicePort ];
}
