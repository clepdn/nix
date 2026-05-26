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
			inputs = {
				nixpkgs.follows = "nixpkgs";
				flake-utils.follows = "flake-utils";
			};
		};
		llama-cpp-src = {
			url = "github:AtomicBot-ai/atomic-llama-cpp-turboquant";
			flake = false;
		};
		direct-vx = {
			url = "git+https://codeberg.org/cowie/direct-vx.git";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.flake-utils.follows = "flake-utils";
		};
		pavement = {
			url = "git+ssh://git@codeberg.org/cowie/md-site.git?ref=release";
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
				({ inputs, ... }: {
					nixpkgs.overlays = [ (final: prev: import ./pkgs { pkgs = prev; lib = prev.lib; } // {
						pi-coding-agent = inputs.pi-mono.packages.${prev.system}.pi;
					}) ];
					home-manager.useGlobalPkgs = true;
					home-manager.extraSpecialArgs = { inherit inputs; };
				})
			] ++ extraModules;
		};
	in
	{
		homeConfigurations.callie = home-manager.lib.homeManagerConfiguration {
			pkgs = import nixpkgs {
				system = "x86_64-linux";
				config.allowUnfree = true;
				overlays = [ (final: prev: import ./pkgs { pkgs = prev; lib = prev.lib; } // {
					pi-coding-agent = inputs.pi-mono.packages.${prev.system}.pi;
				}) ];
			};
			extraSpecialArgs = { inherit inputs self; };
			modules = [ ./users/callie/home.nix ];
		};

		nixosConfigurations = {
			deck    = mkHost "deck"    [ inputs.jovian.nixosModules.jovian ];
			sayaka  = mkHost "sayaka"  [ inputs.disko.nixosModules.disko
						     inputs.direct-vx.nixosModules.default ];
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
