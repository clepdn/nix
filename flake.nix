{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		jovian = {
			url = "github:Jovian-Experiments/Jovian-NixOS";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs = {
				nixpkgs.follows = "nixpkgs";
				home-manager.follows = "home-manager"; 
			};
		};
		lanzaboote = {
			url = "github:nix-community/lanzaboote/v1.0.0";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		/*
		apple-color-emoji = {
		      url = "github:samuelngs/apple-emoji-linux";
		      inputs.nixpkgs.follows = "nixpkgs";  
		};
		*/
		agenix = {
			url = "github:ryantm/agenix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		nixvim = {
			url = "github:nix-community/nixvim";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		flake-utils.url = "github:numtide/flake-utils";
		disko = {
			url = "github:nix-community/disko";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		slugtan = {
			url = "git+ssh://git@codeberg.org/cowie/slugbot.git";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		pi-mono = {
			url = "git+https://codeberg.org/cowie/pi-fork.git";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		llama-cpp-src = {
			url = "github:ggml-org/llama.cpp";
			flake = false;
		};
	};

	outputs =
	inputs @ { self, nixpkgs, flake-utils, home-manager, ... }:

	let
		mkHost = host: extraModules: nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs self; clib = import ./lib nixpkgs.lib; };
			modules = [
				./hosts/${host}
				inputs.agenix.nixosModules.default
				inputs.home-manager.nixosModules.home-manager
				({ pkgs, ... }: {
					nixpkgs.overlays = [ (final: prev: import ./pkgs { pkgs = prev; lib = prev.lib; } // {
						pi = inputs.pi-mono.packages.${prev.system}.pi;
					}) ];
				})
			] ++ extraModules;
		};
	in
	{
		nixosConfigurations = {
			deck    = mkHost "deck"    [ inputs.jovian.nixosModules.jovian ];
			sayaka  = mkHost "sayaka"  [ inputs.disko.nixosModules.disko ];
			madoka  = mkHost "madoka"  [ inputs.lanzaboote.nixosModules.lanzaboote ];
			homura  = mkHost "homura"  [ inputs.jovian.nixosModules.jovian 
						     inputs.slugtan.nixosModules.default ];
		};
	}

	// flake-utils.lib.eachDefaultSystem(system: let 
		pkgs = import nixpkgs { inherit system; };
	in {
		devShells.default = pkgs.mkShell {
			packages = with pkgs; [
				inputs.agenix.packages.${system}.default
			];
		};
	});
}
