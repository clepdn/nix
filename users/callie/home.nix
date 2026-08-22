{ pkgs, inputs, ... }: {
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
      inputs.omp.packages.${pkgs.system}.default
      claude-code
      codex
      fastfetch
      hyfetch
    ];
    stateVersion = "25.11";
  };
}
