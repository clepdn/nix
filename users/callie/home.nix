{ pkgs, lib, inputs, mypkgs, ... }: {
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../../modules/fish
    ../../modules/nvim
    ../../modules/nmux
    ../../modules/hm-age-pq
  ];

  programs.home-manager.enable = true;

  home = {
    username = "callie";
    homeDirectory = "/home/callie";
    packages = with pkgs; [
      mypkgs.omp
      claude-code
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
}
