{ pkgs, lib, inputs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../../modules/nvim
    ../../modules/nmux
    ../../modules/hm-age-pq
  ];

  programs.home-manager.enable = true;
  #programs.fish.enable = true;
  home.sessionVariables.HAPPY_SERVER_URL = "https://happy.on-her.computer";

  home = {
    username = "callie";
    homeDirectory = "/home/callie";
    packages = with pkgs; [
      helium
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

  age.identityPaths = [ "/home/callie/.age/identity" ];

  systemd.user.services.generate-pq-agekey = {
    description = "Generate user PQ age identity key";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f "$HOME/.age/identity" ]; then
        mkdir -p "$HOME/.age"
        ${pkgs.age}/bin/age-keygen -pq -o "$HOME/.age/identity"
        chmod 600 "$HOME/.age/identity"
        chown callie:users "$HOME/.age/identity"
      fi
    '';
  };
}
