{ pkgs, lib, inputs, ... }: {
  imports = [
    ../../modules/nvim
    ../../modules/nmux
  ];

  home = {
    username = "callie";
    homeDirectory = "/home/callie";
    packages = with pkgs; [
      inputs.pi-mono.packages.${pkgs.system}.default
    ];
    stateVersion = "25.11";
  };

  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.pi/agent/settings.json"
    mkdir -p "$(dirname "$settings")"
    if [ ! -f "$settings" ]; then
      echo '{}' > "$settings"
    fi
    current=$(cat "$settings")
    echo "$current" \
      | ${pkgs.jq}/bin/jq '
          .defaultProvider = "anthropic"
          | .defaultThinkingLevel = "medium"
          | .packages = [
              "https://github.com/nicobailon/pi-web-access",
              "https://github.com/nicobailon/pi-subagents"
            ]
        ' > "$settings.tmp" && mv "$settings.tmp" "$settings"
  '';
}
