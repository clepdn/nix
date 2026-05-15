{ pkgs, lib, inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../../modules/nvim
    ../../modules/nmux
  ];

  programs.home-manager.enable = true;
  #programs.fish.enable = true;
  home.sessionVariables.HAPPY_SERVER_URL = "https://happy.on-her.computer";

  home = {
    username = "callie";
    homeDirectory = "/home/callie";
    packages = with pkgs; [
      happyCli
      (symlinkJoin {
        name = "pi";
        paths = [ inputs.pi-mono.packages.${pkgs.system}.default ];
        buildInputs = [ makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/pi \
            --prefix PATH : ${lib.makeBinPath [ nodejs ]}
        '';
      })
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
