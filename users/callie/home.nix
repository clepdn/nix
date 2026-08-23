{ pkgs, inputs, mypkgs, ... }: {
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
      claude-code
      codex
      fastfetch
      hyfetch
      mypkgs.omp
    ];
    stateVersion = "25.11";
  };
}
